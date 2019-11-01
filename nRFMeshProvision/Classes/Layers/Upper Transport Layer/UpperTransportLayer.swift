/*
* Copyright (c) 2019, Nordic Semiconductor
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

internal class UpperTransportLayer {
    private let networkManager: NetworkManager
    private let meshNetwork: MeshNetwork
    private let defaults: UserDefaults
    private let mutex = DispatchQueue(label: "UpperTransportLayerMutex")
    
    private var logger: LoggerDelegate? {
        return networkManager.manager.logger
    }
    
    /// The upper transport layer shall not transmit a new segmented
    /// Upper Transport PDU to a given destination until the previous
    /// Upper Transport PDU to that destination has been either completed
    /// or cancelled.
    ///
    /// This map contains queues of messages targetting each destination.
    private var queues: [Address : [(pdu: UpperTransportPdu, ttl: UInt8?, networkKey: NetworkKey)]]
    
    init(_ networkManager: NetworkManager) {
        self.networkManager = networkManager
        self.meshNetwork = networkManager.meshNetwork!
        self.defaults = UserDefaults(suiteName: meshNetwork.uuid.uuidString)!
        self.queues = [:]
    }
    
    /// Handles received Lower Transport PDU.
    /// Depending on the PDU type, the message will be either propagated to
    /// Access Layer, or handled internally.
    ///
    /// - parameter lowetTransportPdu: The Lower Trasport PDU received.
    func handle(lowerTransportPdu: LowerTransportPdu) {
        switch lowerTransportPdu.type {
        case .accessMessage:
            let accessMessage = lowerTransportPdu as! AccessMessage
            if let (upperTransportPdu, keySet) = UpperTransportPdu.decode(accessMessage, for: meshNetwork) {
                logger?.i(.upperTransport, "\(upperTransportPdu) received")
                networkManager.accessLayer.handle(upperTransportPdu: upperTransportPdu, sentWith: keySet)
            } else {
                logger?.w(.upperTransport, "Failed to decode PDU")
            }
        case .controlMessage:
            let controlMessage = lowerTransportPdu as! ControlMessage
            switch controlMessage.opCode {
            case 0x0A:
                if let heartbeat = HearbeatMessage(fromControlMessage: controlMessage) {
                    logger?.i(.upperTransport, "\(heartbeat) received")
                    handle(hearbeat: heartbeat)
                }
            default:
                logger?.w(.upperTransport, "Unsupported Control Message received (opCode: \(controlMessage.opCode))")
                // Other Control Messages are not supported.
                break
            }
        }
    }
    
    /// Encrypts the Access PDU using given key set and sends it down to
    /// Lower Transport Layer.
    ///
    /// - parameters:
    ///   - pdu: The Access PDU to be sent.
    ///   - initialTtl: The initial TTL (Time To Live) value of the message.
    ///                 If `nil`, the default Node TTL will be used.
    ///   - keySet: The set of keys to encrypt the message with.
    func send(_ accessPdu: AccessPdu, withTtl initialTtl: UInt8?, using keySet: KeySet) {
        // Get the current sequence number for source Element's address.
        let source = accessPdu.localElement!.unicastAddress
        let sequence = UInt32(defaults.integer(forKey: "S\(source.hex)"))
        let networkKey = keySet.networkKey
        
        let pdu = UpperTransportPdu(fromAccessPdu: accessPdu,
                                    usingKeySet: keySet, sequence: sequence)
        
        logger?.i(.upperTransport, "Sending \(pdu) encrypted using key: \(keySet)")
        
        let isSegmented = pdu.transportPdu.count > 15 || accessPdu.isSegmented
        if isSegmented {
            // Enqueue the PDU. If the queue was empty, the PDU will be sent
            // immediately.
            enqueue(pdu: pdu, initialTtl: initialTtl, networkKey: networkKey)
        } else {
            networkManager.lowerTransportLayer.send(unsegmentedUpperTransportPdu: pdu,
                                                    withTtl: initialTtl, usingNetworkKey: networkKey)
        }
    }
    
    /// Cancels sending all segmented messages matching given handle.
    /// Unsegmented messages are sent almost instantaneously and cannot be
    /// cancelled.
    ///
    /// - parameter handle: The message handle.
    func cancel(_ handle: MessageHandle) {
        var shouldSendNext = false
        // Check if the message that is currently being sent mathes the
        // handler data. If so, cancel it.
        if let first = mutex.sync(execute: { queues[handle.destination]?.first }),
           first.pdu.message!.opCode == handle.opCode && first.pdu.source == handle.source {
               logger?.d(.upperTransport, "Cancelling sending \(first.pdu)")
               networkManager.lowerTransportLayer.cancelSending(segmentedUpperTransportPdu: first.pdu)
               shouldSendNext = true
        }

        // Remove all enqueued messages that match the handler.
        mutex.sync {
            queues[handle.destination]?.removeAll() {
                $0.pdu.message!.opCode == handle.opCode &&
                $0.pdu.source == handle.source &&
                $0.pdu.destination == handle.destination
            }
        }
        // If sending a message was cancelled, try sending another one.
        if shouldSendNext {
            lowerTransportLayerDidSend(segmentedUpperTransportPduTo: handle.destination)
        }
    }
    
    /// Returns whether the underlying layer is in progress of
    /// receiving a message from the given address.
    ///
    /// - parameter address: The source address.
    /// - returns: `True` is some, but not all packets of a segmented
    ///            message were received from the given source address;
    ///            `false` if no packets were received or the message
    ///            was complete before calling this method.
    func isReceivingResponse(from address: Address) -> Bool {
        return networkManager.lowerTransportLayer.isReceivingMessage(from: address)
    }
    
    /// A callback called by the lower transport layer when the segmented PDU
    /// has been sent to the given destination.
    ///
    /// This method removes the sent PDU from the queue and initiates sending
    /// a next one, had it been enqueued.
    ///
    /// - parameter destination: The destination address.
    func lowerTransportLayerDidSend(segmentedUpperTransportPduTo destination: Address) {
        mutex.sync {
            guard queues[destination]?.isEmpty == false else {
                return
            }
            // Remove the PDU that has just been sent.
            _ = queues[destination]?.removeFirst()
        }
        // Try to send the next one.
        sendNext(to: destination)
    }
}

private extension UpperTransportLayer {
    
    /// Enqueues the PDU to be sent using the given Network Key.
    ///
    /// - parameters:
    ///   - pdu: The Upper Transport PDU to be sent.
    ///   - initialTtl: The initial TTL (Time To Live) value of the message.
    ///                 If `nil`, the default Node TTL will be used.
    ///   - networkKey: The Network Key to encrypt the PDU with.
    func enqueue(pdu: UpperTransportPdu, initialTtl: UInt8?, networkKey: NetworkKey) {
        var count = 0
        mutex.sync {
            queues[pdu.destination] = queues[pdu.destination] ?? []
            queues[pdu.destination]!.append((pdu: pdu, ttl: initialTtl, networkKey: networkKey))
            count = queues[pdu.destination]!.count
        }
        if count == 1 {
            sendNext(to: pdu.destination)
        }
    }
    
    /// Sends the next enqueued PDU.
    ///
    /// If the queue for the given destination does not exist or is empty,
    /// this method does nothing.
    ///
    /// - parameter destination: The destination address.
    func sendNext(to destination: Address) {
        guard let (pdu, ttl, networkKey) = mutex.sync(execute: { queues[destination]?.first }) else {
            return
        }
        // If another PDU has been enqueued, send it.
        networkManager.lowerTransportLayer.send(segmentedUpperTransportPdu: pdu,
                                                withTtl: ttl, usingNetworkKey: networkKey)
    }
    
}

private extension UpperTransportLayer {
    
    func handle(hearbeat: HearbeatMessage) {
        // TODO: Implement handling Heartbeat messages
    }
    
}
