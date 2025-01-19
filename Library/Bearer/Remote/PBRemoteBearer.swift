/*
* Copyright (c) 2023, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

final private class Send: AsyncResultOperation<Void, Error>, @unchecked Sendable {
    private let message: RemoteProvisioningPDUSend
    private let destination: Address
    private let manager: MeshNetworkManager
    
    private var shouldRetry = true

    init(message: RemoteProvisioningPDUSend, to destination: Address, over manager: MeshNetworkManager,
         completion: ((_ result: Result<Void, Error>) -> Void)?) {
        self.message = message
        self.destination = destination
        self.manager = manager
        super.init()
        self.onResult = completion
    }

    override func main() {
        _ = try? manager.send(message, to: destination) { result in
            do {
                try result.get()
            } catch {
                self.manager.logger?.e(.bearer, "Sending \(self.message) to \(self.destination.hex) failed with error: \(error)")
                if case LowerTransportError.timeout = error {
                    self.cancel(with: error)
                    self.finish()
                }
            }
        }
        
        let callback: (Result<RemoteProvisioningPDUOutboundReport, Error>) -> () = { response in
            guard !self.isCancelled else { return }
            do {
                let _ = try response.get()
                self.finish(with: .success(()))
            } catch {
                if self.shouldRetry {
                    self.manager.logger?.log(message: "Retrying sending \(self.message)", ofCategory: .bearer, withLevel: .warning)
                    self.shouldRetry = false
                    self.main()
                } else {
                    self.finish(with: .failure(error))
                }
            }
        }
        try? manager.waitFor(messageFrom: destination, timeout: 15, completion: callback)
    }
}

/// Implementation of the PB Remote bearer.
open class PBRemoteBearer: ProvisioningBearer {
    
    // MARK: - Properties
    
    public weak var delegate: BearerDelegate?
    public weak var dataDelegate: BearerDataDelegate?
    public private(set) var isOpen: Bool = false
    
    /// The logger receives logs sent from the bearer. The logs will contain
    /// raw data of sent and received packets, as well as connection events.
    public weak var logger: LoggerDelegate?
    
    /// The UUID of the Unprovisioned Device.
    ///
    /// This UUID will be used to identify and open the link between the Provisioner and Provisionee.
    public let unprovisionedDeviceUUID: UUID
    
    /// The Network Manager is responsible for encoding and decoding messages.
    private let meshNetworkManager: MeshNetworkManager
    /// The Unicast Address of an Element with Remote Provisioning Server model
    /// on the Remote Provisioner used to rely provisioning messages.
    public let address: Address
    
    /// A flag indicating whether ``PBRemoteBearer/open()`` method was called.
    private var isOpened: Bool = false
    
    /// Outbound queue of messages.
    private var outboundPduQueue: OperationQueue
    /// Outbound PDU Count.
    ///
    /// The first PDU shall be sent with count set to 1 and the count should
    /// be incremented by 1 for each PDU.
    private var outboundPduCount: UInt8 = 0
    
    // MARK: - Computed properties
    
    public var supportedPduTypes: PduTypes {
        return [.provisioningPdu]
    }
    
    // MARK: - Public API
    
    public init(target uuid: UUID, using server: Model, over manager: MeshNetworkManager) throws {
        guard server.isRemoteProvisioningServer,
              let parentElement = server.parentElement else {
            throw BearerError.bearerClosed
        }
        self.unprovisionedDeviceUUID = uuid
        self.address = parentElement.unicastAddress
        self.meshNetworkManager = manager
        
        // We want to enqueue outgoing PDUs and send a new one only
        // when it has been confirmed with PDU Outbound Report.
        self.outboundPduQueue = OperationQueue()
        self.outboundPduQueue.maxConcurrentOperationCount = 1
    }
    
    public func open() throws {
        guard !isOpened else { return }
        isOpened = true
        
        // Register link status handler.
        // The handler will observe status of the link between Remote Provisioning Server
        // and the Provisionee.
        let linkStatusHandler: (RemoteProvisioningLinkReport) -> () = { report in
            switch report.linkState {
            case .linkActive:
                self.bearerDidOpen()
            case .linkClosing, .idle:
                self.bearerDidClose(with: nil)
            default:
                break
            }
        }
        try! meshNetworkManager.registerCallback(forMessagesFrom: address, callback: linkStatusHandler)
        
        // Send Link Open request.
        let linkOpen = RemoteProvisioningLinkOpen(uuid: unprovisionedDeviceUUID)
        try meshNetworkManager.send(linkOpen, to: address) { result in
            do {
                if let status = try result.get() as? RemoteProvisioningLinkStatus, status.isSuccess {
                    // Usually, the link state will be `.linkOpening` and we will
                    // get a link report moment later.
                    if status.linkState == .linkActive {
                        self.bearerDidOpen()
                    }
                }
            } catch {
                self.bearerDidClose(with: error)
            }
        }
    }
    
    public func close() throws {
        guard isOpen else { return }
        
        let linkClose = RemoteProvisioningLinkClose(reason: .success)
        try meshNetworkManager.send(linkClose, to: address) { result in
            // No matter what result we get, the link is considered closed.
            self.bearerDidClose(with: nil)
        }
    }
    
    public func send(_ data: Data, ofType type: PduType) throws {
        // We only support what we support, right?
        guard supports(type) else {
            throw BearerError.pduTypeNotSupported
        }
        guard isOpen else {
            throw BearerError.bearerClosed
        }
        
        // The data has to be converted again to Provisioning Request
        // to be added to PDU Send request.
        let request = try ProvisioningRequest(from: data)
        outboundPduCount += 1
        let message = RemoteProvisioningPDUSend(outboundPduNumber: outboundPduCount, request: request)
        let operation = Send(message: message, to: address, over: meshNetworkManager) { result in
            guard let _ = try? result.get() else {
                // Sending RemoteProvisioningPDUSend failed.
                // There's no other way to notify the sender.
                self.outboundPduQueue.cancelAllOperations()
                try? self.close()
                return
            }
        }
        outboundPduQueue.addOperation(operation)
    }
    
    private func bearerDidOpen() {
        guard !isOpen else { return }
        
        // When the bearer is open, set up a PDU handler to pass received PDUs to the data delegate.
        let pduHandler: (RemoteProvisioningPDUReport) -> () = { report in
            let data = report.response.pdu
            self.dataDelegate?.bearer(self, didDeliverData: data, ofType: .provisioningPdu)
        }
        try! meshNetworkManager.registerCallback(forMessagesFrom: address, callback: pduHandler)
        
        // Notify the delegate.
        isOpen = true
        outboundPduCount = 0
        delegate?.bearerDidOpen(self)
    }
    
    private func bearerDidClose(with error: Error?) {
        // Unregister PDU handler and link status handler.
        if isOpened {
            meshNetworkManager.unregisterCallback(forMessagesWithType: RemoteProvisioningLinkReport.self, from: address)
        }
        if isOpen {
            meshNetworkManager.unregisterCallback(forMessagesWithType: RemoteProvisioningPDUReport.self, from: address)
        }
        
        // Notify the delegate.
        isOpen = false
        isOpened = false
        delegate?.bearer(self, didClose: error)
    }
    
}
