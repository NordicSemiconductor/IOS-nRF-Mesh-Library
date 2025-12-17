//
//  SuitManager.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 28/5/24.
//

import Foundation
import SwiftCBOR

// MARK: - SuitManager

public class SuitManager: McuManager {
    
    // MARK: Constants
    
    private static let POLLING_WINDOW_MS = 5000
    private static let POLLING_INTERVAL_MS = 150
    private static let MAX_POLL_ATTEMPTS: Int = POLLING_WINDOW_MS / POLLING_INTERVAL_MS
    
    // MARK: TAG
    
    override class var TAG: McuMgrLogCategory { .suit }
    
    // MARK: IDs
    
    enum SuitID: UInt8 {
        /**
         Command allows to get information about roles of manifests supported by the device.
         */
        case manifestList = 0
        /**
         Command allows to get information about the configuration of supported manifests
         and selected attributes of installed manifests of specified role.
         */
        case manifestState = 1
        /**
         Command delivers a packet of a SUIT envelope to the device.
         */
        case envelopeUpload = 2
        /**
         SUIT command sequence has the ability of conditional execution of directives, i.e.
         based on the digest of installed image. That opens scenario where SUIT candidate
         envelope contains only SUIT manifests, images (those required to be updated) are
         fetched by the device only if it is necessary. In that case, the device informs the
         SMP client that specific image is required (and this is what this command
         implements), and then the SMP client delivers requested image in chunks. Due to the
         fact that SMP is designed in clients-server pattern and lack of server-sent
         notifications, implementation bases on polling.
         */
        case pollImageState = 3
        /**
         Command delivers a packet of a resource requested by the target device.
         */
        case uploadResource = 4
        /**
         Command delivers a packet of a SUIT Cache to the target device. A SUIT Cache is neither an Envelope nor a Resource. It's more akin to additional Envelope Data, but separate from it and possibly directed towards specific device partition(s) (aka 'images' in McuBoot parlance)
         */
        case uploadCache = 5
        /**
         Command erases DFU and DFU Cache partitions.
         */
        case cleanup = 6
    }
    
    // MARK: Properties
    
    private var offset: UInt64 = 0
    private var uploadData: Data!
    private var uploadImages: [ImageManager.Image] = []
    private var uploadIndex: Int = 0
    private var uploadPipeline: McuMgrUploadPipeline!
    private var pollAttempts: Int = 0
    private var sessionID: UInt64?
    private var targetID: UInt64?
    private var state: SuitManagerState = .none
    private weak var uploadDelegate: SuitManagerDelegate?
    
    private var callback: McuMgrCallback<SuitListResponse>?
    private var roleIndex: Int?
    private var roles: [McuMgrManifestListResponse.Manifest.Role] = []
    private var responses: [McuMgrManifestStateResponse] = []
    
    // MARK: Init
    
    public init(transport: McuMgrTransport) {
        super.init(group: McuMgrGroup.suit, transport: transport)
    }
    
    // MARK: List
    
    /**
     Command allows to get information about roles of manifests supported by the device.
     */
    public func listManifest(callback: @escaping McuMgrCallback<SuitListResponse>) {
        self.callback = callback
        roleIndex = 0
        roles = []
        responses = []
        send(op: .read, commandId: SuitID.manifestList, payload: nil, 
             callback: listManifestCallback)
    }
    
    private func validateNext() {
        guard let i = roleIndex else { return }
        if i < roles.count {
            let role = roles[i]
            logDelegate?.log("Sending Manifest State command for Role \(role.description)",
                             ofCategory: .suit, atLevel: .verbose)
            getManifestState(for: role, callback: roleStateCallback)
        } else {
            guard roles.count == responses.count else {
                callback?(nil, SuitManagerError.listRoleResponseMismatch(roleCount: roles.count, responseCount: responses.count))
                return
            }
            
            let mandatoryHeaderData = McuManager.buildPacket(scheme: .ble, version: .SMPv2,
                                                             op: .read, flags: 0,
                                                             group: McuMgrGroup.suit.rawValue,
                                                             sequenceNumber: 0,
                                                             commandId: SuitID.manifestList,
                                                             payload: [:])
            let suitResponse = try? SuitListResponse(cbor: nil)
            suitResponse?.header = try? McuMgrHeader(data: mandatoryHeaderData)
            suitResponse?.roles = roles
            suitResponse?.states = responses
            callback?(suitResponse, nil)
        }
    }
    
    // MARK: List Manifest Callback
    
    private lazy var listManifestCallback: McuMgrCallback<McuMgrManifestListResponse> = { [weak self] response, error in
        guard let self else { return }
        
        guard error == nil, let response, response.rc.isSupported() else {
            self.logDelegate?.log("List Manifest Callback not Supported.", ofCategory: .suit, atLevel: .error)
            self.callback?(nil, error)
            return
        }
        
        let roles = response.manifests.compactMap(\.role)
        self.roleIndex = 0
        self.roles = roles
        if #available(iOS 13.0, macOS 10.15, *) {
            let rolesList = ListFormatter.localizedString(byJoining: roles.map(\.description))
            self.logDelegate?.log("Received Response with Roles: \(rolesList)", ofCategory: .suit, atLevel: .debug)
        }
        self.validateNext()
    }
    
    // MARK: Role State Callback
    
    private lazy var roleStateCallback: McuMgrCallback<McuMgrManifestStateResponse> = { [weak self] response, error in
        guard let self else { return }
        guard error == nil, let response, response.rc.isSupported() else {
            self.logDelegate?.log("List Manifest Callback not Supported.", ofCategory: .suit, atLevel: .error)
            return
        }
        self.responses.append(response)
        self.roleIndex? += 1
        self.validateNext()
    }
    
    /**
     Command allows to get information about the configuration of supported manifests
     and selected attributes of installed manifests of specified role (asynchronous).
     */
    public func getManifestState(for role: McuMgrManifestListResponse.Manifest.Role,
                                 callback: @escaping McuMgrCallback<McuMgrManifestStateResponse>) {
        let fixCallback: McuMgrCallback<McuMgrManifestStateResponse> = { response, error in
            callback(response, error)
        }
        
        let payload: [String:CBOR] = [
            "role": CBOR.unsignedInt(role.rawValue)
        ]
        send(op: .read, commandId: SuitID.manifestState, payload: payload,
             callback: fixCallback)
    }
    
    // MARK: Cleanup
    
    /**
     Erase DFU and DFU Cache partitions.
     */
    public func cleanup(callback: @escaping McuMgrCallback<McuMgrResponse>) {
        send(op: .write, commandId: SuitID.cleanup, payload: [:],
             callback: callback)
    }
    
    // MARK: Poll
    
    /**
     * Poll for required image
     *
     * SUIT command sequence has the ability of conditional execution of directives, i.e. based on the digest of installed image. That opens a scenario where SUIT candidate envelope contains only SUIT manifests, images (those required to be updated) are fetched by the device only if it is necessary. In that case, the device informs the SMP client that specific image is required via callback (and this is what this command implements), and then the SMP client uploads requested image. Due to the fact that SMP is designed in client-server pattern and lack of server-sent notifications, implementation is based on polling.
     *
     * After sending the Envelope, the client should periodically poll the device to check if an image is required.
     *
     * - Parameter callback: the asynchronous callback.
     */
    public func poll(callback: @escaping McuMgrCallback<McuMgrPollResponse>) {
        send(op: .read, commandId: SuitID.pollImageState, payload: nil, callback: callback)
    }
    
    // MARK: upload(_:delegate:)
    
    public func upload(_ images: [ImageManager.Image], using configuration: FirmwareUpgradeConfiguration, delegate: SuitManagerDelegate?) {
        verifyOnMainThread()
        
        // Sort Images so Envelope is at index zero.
        uploadImages = images.sorted(by: { l, _ in
            l.content == .suitEnvelope
        })
        uploadIndex = 0
        let deferInstall = uploadImages.contains(where: { $0.content == .suitCache })
        if deferInstall {
            self.logDelegate?.log("Suit Cache Image Detected for Upload. Enabling `deferInstall`.", ofCategory: .suit, atLevel: .debug)
        }
        
        resetUploadVariables()
        uploadData = images[uploadIndex].data
        uploadDelegate = delegate
        uploadPipeline = McuMgrUploadPipeline(adopting: configuration, over: transport)
        state = .uploadingEnvelope
        upload(uploadData, deferInstall: deferInstall, at: offset)
    }
    
    // MARK: processRecentlyUploadedEnvelope(callback:)
    
    /**
     Equivalent of McuManager's 'Confirm' Command for SUIT.
     
     To trigger 'confirm' or processing of recently uploaded Envelope, we need to send an 'upload envelope' command specifying data size of zero, offset zero and no defer install (which defaults to false anyway).
     */
    public func processRecentlyUploadedEnvelope(callback: @escaping McuMgrCallback<McuMgrResponse>) {
        resetUploadVariables()
        state = .uploadComplete
        
        let payload: [String: CBOR] = [
            "off": CBOR.unsignedInt(0),
            "len": CBOR.unsignedInt(0)
        ]
        send(op: .write, commandId: SuitID.envelopeUpload, payload: payload,
             timeout: McuManager.DEFAULT_SEND_TIMEOUT_SECONDS, callback: callback)
    }
    
    // MARK: processUploadedEnvelopeCallback
    
    private lazy var processUploadedEnvelopeCallback: McuMgrCallback<McuMgrResponse> = { [weak self] response, error in
        guard let self = self else { return }
        
        if let error {
            self.uploadDelegate?.uploadDidFail(with: error)
        }
        
        if let response {
            switch response.result {
            case .failure(let error):
                self.uploadDelegate?.uploadDidFail(with: error)
            case .success:
                self.startPolling()
            }
        }
    }
    
    // MARK: Upload Resource
    
    public func uploadResource(_ resourceData: Data) {
        offset = 0
        pollAttempts = 0
        uploadData = resourceData
        state = .uploadingResource
        // Keep uploadDelegate AND sessionID
        upload(resourceData, at: offset)
    }
    
    // MARK: upload(_:deferInstall:delegate)
    
    private func upload(_ data: Data, deferInstall: Bool = false, at offset: UInt64) {
        var uploadTimeoutInSeconds: Int
        if offset == 0 {
            // When uploading offset 0, we might trigger an erase on the firmware's end.
            // Hence, the longer timeout.
            uploadTimeoutInSeconds = McuManager.DEFAULT_SEND_TIMEOUT_SECONDS
        } else {
            uploadTimeoutInSeconds = McuManager.FAST_TIMEOUT
        }
        
        let commandID: SuitID
        if targetID != nil {
            commandID = .uploadCache
            // Device will probably restart itself in preparation for .cacheUpload,
            // so we need to retry quickly.
            uploadTimeoutInSeconds = McuManager.FAST_TIMEOUT
        } else if sessionID != nil {
            commandID = .uploadResource
        } else {
            commandID = .envelopeUpload
        }
        
        let packetLength = maxDataPacketLengthFor(data: data, offset: offset)
        let payload = buildPayload(for: data, at: offset, with: packetLength)
        send(op: .write, commandId: commandID, payload: payload,
             timeout: uploadTimeoutInSeconds, callback: uploadCallback)
    }
    
    // MARK: uploadCallback
    
    private lazy var uploadCallback: McuMgrCallback<McuMgrUploadResponse> = { [weak self] response, error in
        guard let self = self else { return }
        
        guard let uploadData = self.uploadData else {
            self.uploadDelegate?.uploadDidFail(with: ImageUploadError.invalidData)
            return
        }
        
        // Check for an error.
        if let error {
            if case let McuMgrTransportError.insufficientMtu(newMtu) = error {
                do {
                    try self.setMtu(newMtu)
                    self.upload(uploadData, at: 0)
                } catch let mtuResetError {
                    self.uploadDelegate?.uploadDidFail(with: mtuResetError)
                }
                return
            }
            self.uploadDelegate?.uploadDidFail(with: error)
            return
        }
        
        guard let response else {
            self.uploadDelegate?.uploadDidFail(with: ImageUploadError.invalidPayload)
            return
        }
        
        if let error = response.getError() {
            self.uploadDelegate?.uploadDidFail(with: error)
            return
        }
        
        if let offset = response.off {
            self.offset = offset
            self.uploadPipeline.receivedData(with: offset)
            self.uploadDelegate?.uploadProgressDidChange(bytesSent: Int(offset), imageSize: uploadData.count,
                                                         timestamp: Date())
            
            if offset < uploadData.count {
                guard self.state.isInProgress else { return }
                
                self.uploadPipeline.pipelinedSend(ofSize: self.uploadData.count) { [unowned self] offset in
                    let payloadLength = self.maxDataPacketLengthFor(data: uploadData, offset: offset)
                    // Note: 'defer install' is not needed for SUIT Cache(s).
                    self.upload(uploadData, at: offset)
                    return offset + payloadLength
                }
            } else {
                // Don't trigger writes to another Core unless all write(s) have returned for
                // the current one.
                guard self.uploadPipeline.allPacketsReceived() else {
                    return
                }
                
                self.uploadIndex += 1
                if self.uploadIndex < self.uploadImages.count {
                    let uploadImage = self.uploadImages[self.uploadIndex]
                    self.offset = 0
                    self.uploadData = uploadImage.data
                    if uploadImage.content == .suitCache {
                        self.targetID = UInt64(uploadImage.image)
                    }
                }
                
                guard self.state.isInProgress else { return }
                
                if self.uploadIndex < self.uploadImages.count {
                    // Note: 'defer install' is not needed for SUIT Cache(s).
                    self.upload(self.uploadData, at: self.offset)
                } else {
                    self.finishUploadAndStartPolling()
                }
            }
        }
    }
    
    // MARK: pause()
    
    public func pause() {
        guard state.isInProgress else {
            log(msg: "Upload is not in progress and therefore cannot be paused.", atLevel: .warning)
            return
        }
        
        state = .uploadPaused
        logDelegate?.log("Data Upload Paused.", ofCategory: .suit, atLevel: .info)
    }
    
    // MARK: continueUpload()
    
    public func continueUpload() {
        guard state == .uploadPaused else {
            logDelegate?.log("Upload is not in progress and therefore cannot be resumed.", ofCategory: .suit, atLevel: .warning)
            return
        }
        
        if uploadIndex < uploadImages.count {
            logDelegate?.log("Resuming Upload.", ofCategory: .suit, atLevel: .application)
            
            let uploadImage = uploadImages[uploadIndex]
            switch uploadImage.content {
            case .suitCache:
                state = .uploadingCache
            case .suitEnvelope:
                state = .uploadingEnvelope
            default:
                state = .uploadingResource
            }
            
            if offset == 0, uploadImage.content == .suitCache {
                targetID = UInt64(uploadImage.image)
            }
            // Note: 'defer install' is not needed for SUIT Cache(s).
            upload(uploadData, at: offset)
        } else {
            finishUploadAndStartPolling()
        }
    }
    
    // MARK: cancel(with:)
    
    public func cancel(with error: Error? = nil) {
        state = .none
        resetUploadVariables()
        uploadDelegate?.uploadDidCancel()
        uploadDelegate = nil
        
        if let error {
            logDelegate?.log("Upload cancelled due to error: \(error)", ofCategory: .suit, atLevel: .error)
        } else {
            logDelegate?.log("Upload cancelled", ofCategory: .suit, atLevel: .application)
        }
    }
    
    // MARK: resetUploadVariables()
    
    private func resetUploadVariables() {
        offset = 0
        pollAttempts = 0
        uploadData = nil
        sessionID = nil
        targetID = nil
    }
    
    // MARK: finishUploadAndStartPolling()
    
    private func finishUploadAndStartPolling() {
        // Upload Finished.
        dataUploadComplete()
        
        let deferredInstall = uploadImages.contains(where: { $0.content == .suitCache })
        if deferredInstall {
            logDelegate?.log("Sending Envelope Processing (Confirm) Command due to Deferred Install.", ofCategory: .suit, atLevel: .info)
            processRecentlyUploadedEnvelope(callback: processUploadedEnvelopeCallback)
        } else {
            startPolling()
        }
    }
    
    // MARK: dataUploadComplete()
    
    private func dataUploadComplete() {
        state = .uploadComplete
        logDelegate?.log("Data Upload Complete.", ofCategory: .suit, atLevel: .info)
        
        // Listen for disconnection event, which signals update is complete on device's end.
        transport.addObserver(self)
    }
    
    // MARK: startPolling()
    
    /**
     Call when all Envelope and Cache uploads have been completed.
     */
    private func startPolling() {
        logDelegate?.log("(SUIT) Polling Start.", ofCategory: .suit, atLevel: .info)
        
        // While waiting for disconnection, poll.
        // The Device might tell us it needs a resource.
        poll(callback: pollingCallback)
    }
    
    // MARK: pollingCallback
    
    private lazy var pollingCallback: McuMgrCallback<McuMgrPollResponse> = { [weak self] response, error in
        guard let self = self else { return }
        
        guard self.state.isInProgress else {
            // Success means firmware device disconnected, which can trigger errors.
            // So if we've considered the upload successful already, we don't care
            // about this callback.
            return
        }
        
        if let error {
            // Assume success, error is most likely due to disconnection.
            // Disconnection means firmware moved on and doesn't need anything from us.
            self.declareSuccess()
        }
        
        if let response {
            guard response.rc.isSupported() else {
                // Not supported, so either no polling, or device restarted.
                // It means success / continue.
                self.declareSuccess()
                return
            }
            
            guard let resourceID = response.resourceID,
                  let resource = FirmwareUpgradeResource(resourceID),
                  let sessionID = response.sessionID else {
                guard self.pollAttempts < Self.MAX_POLL_ATTEMPTS else {
                    self.declareSuccess()
                    return
                }
                
                // Empty response means 'keep waiting'. So we'll just retry.
                let waitTime: DispatchTimeInterval = .milliseconds(Self.POLLING_INTERVAL_MS)
                DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) { [unowned self] in
                    self.pollAttempts += 1
                    self.poll(callback: self.pollingCallback)
                }
                return
            }
            
            self.sessionID = sessionID
            guard self.uploadDelegate != nil else {
                self.uploadDelegate?.uploadDidFail(with: SuitManagerError.suitDelegateRequiredForResource(resource))
                return
            }
            // Stop listening for disconnection since firmware has requested a resource.
            self.transport.removeObserver(self)
            // Ask API user for the requested resource.
            self.uploadDelegate?.uploadRequestsResource(resource)
        }
    }
    
    // MARK: declareSuccess()
    
    private func declareSuccess() {
        logDelegate?.log("Success!", ofCategory: .suit, atLevel: .application)
        transport.removeObserver(self)
        state = .success
        uploadDelegate?.uploadDidFinish()
    }
    
    // MARK: Packet Calculation
    
    private func maxDataPacketLengthFor(data: Data, offset: UInt64) -> UInt64 {
        guard offset < data.count else {
            return UInt64(McuMgrHeader.HEADER_LENGTH)
        }
        
        let remainingBytes = UInt64(data.count) - offset
        let packetOverhead = calculatePacketOverhead(data: data, offset: offset)
        let maxDataLength = UInt64(transport.mtu) - UInt64(packetOverhead)
        return min(maxDataLength, remainingBytes)
    }
    
    private func calculatePacketOverhead(data: Data, offset: UInt64) -> Int {
        let headerLength = UInt64(MemoryLayout<UInt8>.size)
        let payload = buildPayload(for: data, at: offset, with: headerLength)
        
        // Build the packet and return the size.
        let packet = McuManager.buildPacket(scheme: transport.getScheme(), version: .SMPv2,
                                            op: .write, flags: 0, group: group.rawValue,
                                            sequenceNumber: 0, commandId: SuitID.envelopeUpload,
                                            payload: payload)
        var packetOverhead = packet.count + 5
        if transport.getScheme().isCoap() {
            // Add 25 bytes to packet overhead estimate for the CoAP header.
            packetOverhead = packetOverhead + 25
        }
        return packetOverhead
    }
    
    // MARK: buildPayload(for:at:)
    
    private func buildPayload(for data: Data, at offset: UInt64, with length: UInt64) -> [String: CBOR] {
        let chunkOffset = offset
        let chunkEnd = min(chunkOffset + length, UInt64(data.count))
        var payload: [String: CBOR] = ["data": CBOR.byteString([UInt8](data[chunkOffset..<chunkEnd])),
                                      "off": CBOR.unsignedInt(chunkOffset)]
        if let sessionID {
            payload.updateValue(CBOR.unsignedInt(sessionID), forKey: "stream_session_id")
        }
        
        if let targetID {
           payload.updateValue(CBOR.unsignedInt(targetID), forKey: "target_id")
       }
        
        if chunkOffset == 0 {
            let deferInstall = uploadImages.contains(where: { $0.content == .suitCache })
            if deferInstall {
                payload.updateValue(CBOR.boolean(deferInstall), forKey: "defer_install")
            }
            payload.updateValue(CBOR.unsignedInt(UInt64(data.count)), forKey: "len")
        }
        return payload
    }
}

// MARK: - ConnectionObserver

extension SuitManager: ConnectionObserver {
    
    public func transport(_ transport: McuMgrTransport, didChangeStateTo state: McuMgrTransportState) {
        // Disregard other states.
        guard state == .disconnected else { return }
        
        log(msg: "Device has disconnected.", atLevel: .info)
        transport.removeObserver(self)
        
        guard self.state == .uploadComplete else { return }
        declareSuccess()
    }
}

// MARK: - SuitManagerState

enum SuitManagerState {
    case none
    case uploadingEnvelope, uploadingCache, uploadingResource, uploadPaused, uploadComplete
    case success
    
    var isInProgress: Bool {
        switch self {
        case .none, .uploadPaused, .success:
            return false
        case .uploadingEnvelope, .uploadingCache, .uploadingResource, .uploadComplete:
            return true
        }
    }
}

// MARK: - SuitManagerError

public enum SuitManagerError: Error, LocalizedError {
    case suitDelegateRequiredForResource(_ resource: FirmwareUpgradeResource)
    case listRoleResponseMismatch(roleCount: Int, responseCount: Int)
    
    public var errorDescription: String? {
        switch self {
        case .suitDelegateRequiredForResource(let resource):
            return "A \(String(describing: SuitFirmwareUpgradeDelegate.self)) delegate is required since the firmware is requesting resource \(resource.description)."
        case .listRoleResponseMismatch(let roleCount, let responseCount):
            return "The number of returned List Roles (\(roleCount) does not match the Manifest States \(responseCount)."
        }
    }
}

// MARK: - SuitManagerDelegate

public protocol SuitManagerDelegate: ImageUploadDelegate {
    
    /**
     In SUIT (Software Update for the Internet of Things), various resources, such as specific files, URL contents, etc. may be requested by the firmware device. When it does, this callback will be triggered.
     */
    func uploadRequestsResource(_ resource: FirmwareUpgradeResource)
}
