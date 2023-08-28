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

private enum Message {
    case lowerTransportPdu(_ pdu: LowerTransportPdu)
    case acknowledgement(_ ack: SegmentAcknowledgmentMessage)
    case none
}

private enum SecurityError: Error {
    /// Thrown internally when a possible replay attack was detected.
    /// This error is not propagated to higher levels, the packet is
    /// being discarded.
    case replayAttack
}

internal class LowerTransportLayer {
    private weak var networkManager: NetworkManager?
    private let meshNetwork: MeshNetwork
    private let mutex = DispatchQueue(label: "LowerTransportLayerMutex")
    
    private var logger: LoggerDelegate? {
        return networkManager?.logger
    }
    
    /// The storage for keeping sequence numbers. Each mesh network (with different UUID)
    /// has a unique storage, which can be reloaded when the network is imported after it
    /// was used before.
    private let defaults: UserDefaults
    
    /// The map of incomplete received segments. Every time a Segmented Message is received
    /// it is added to the map to an ordered array. When all segments are received
    /// they are sent for processing to higher layer.
    ///
    /// The key consists of 16 bits of source address in 2 most significant bytes
    /// and `sequenceZero` field in 13 least significant bits.
    /// See `UInt32(keyFor:sequenceZero)` below.
    private var incompleteSegments: [UInt32 : [SegmentedMessage?]]
    /// This map contains Segment Acknowledgment Messages of completed messages.
    /// It is used when a complete Segmented Message has been received and the
    /// ACK has been sent but failed to reach the source Node.
    /// The Node would then resend all non-acknowledged segments and expect a new ACK.
    /// Without this map, this layer would have to complete again all segments in
    /// order to send the ACK. By checking if a segment comes from an already
    /// acknowledged message, it can immediately send the ACK again.
    ///
    /// An item is removed when a next message has been received from the same Node.
    private var acknowledgments: [Address : SegmentAcknowledgmentMessage]
    /// The map of active timers. Every message has `defaultIncompleteTimerInterval`
    /// seconds to be completed (timer resets when next segment was received).
    /// After that time the segments are discarded.
    ///
    /// The key consists of 16 bits of source address in 2 most significant bytes
    /// and `sequenceZero` field in 13 least significant bits.
    /// See `UInt32(keyFor:sequenceZero)` below.
    private var incompleteTimers: [UInt32 : BackgroundTimer]
    /// The map of acknowledgment timers. After receiving a segment targeting
    /// any of the Unicast Addresses of one of the Elements of the local Node, a
    /// timer is started that will send the Segment Acknowledgment Message for
    /// segments received until than. The timer is invalidated when the message
    /// has been completed.
    ///
    /// The key consists of 16 bits of source address in 2 most significant bytes
    /// and `sequenceZero` field in 13 least significant bits.
    /// See `UInt32(keyFor:sequenceZero)` below.
    private var acknowledgmentTimers: [UInt32 : BackgroundTimer]
    
    /// The map of outgoing segmented messages.
    ///
    /// The key is the `sequenceZero` of the message.
    private var outgoingSegments: [UInt16: (destination: MeshAddress, segments: [SegmentedMessage?])]
    /// The map of segment transmission timers. A segment transmission timer
    /// for a Segmented Message with `sequenceZero` is started whenever such
    /// message is sent to a Unicast Address. After the timer expires, the
    /// layer will resend all non-confirmed segments and reset the timer.
    ///
    /// The key is the `sequenceZero` of the message.
    private var segmentTransmissionTimers: [UInt16 : BackgroundTimer]
    /// The initial TTL values.
    ///
    /// The key is the `sequenceZero` of the message.
    private var segmentTtl: [UInt16 : UInt8]
    
    init(_ networkManager: NetworkManager) {
        self.networkManager = networkManager
        self.meshNetwork = networkManager.meshNetwork
        self.defaults = UserDefaults(suiteName: meshNetwork.uuid.uuidString)!
        self.incompleteSegments = [:]
        self.incompleteTimers = [:]
        self.acknowledgmentTimers = [:]
        self.outgoingSegments = [:]
        self.segmentTransmissionTimers = [:]
        self.acknowledgments = [:]
        self.segmentTtl = [:]
    }
    
    /// This method handles the received Network PDU. If needed, it will reassembly
    /// the message, send block acknowledgment to the sender, and pass the Upper
    /// Transport PDU to the Upper Transport Layer.
    ///
    /// - parameter networkPdu: The Network PDU received.
    func handle(networkPdu: NetworkPdu) {
        guard let networkManager = networkManager else { return }
        // Some validation, just to be sure. This should pass for sure.
        guard networkPdu.transportPdu.count > 1 else {
            return
        }
                
        // Segmented messages must be validated and assembled in thread safe way.
        let result: Result<Message, Error> = mutex.sync {
            guard checkAgainstReplayAttack(networkPdu) else {
                return .failure(SecurityError.replayAttack)
            }

            // Lower Transport Messages can be Unsegmented or Segmented.
            // This information is stored in the most significant bit of the first octet.
            let segmented = networkPdu.isSegmented
            
            if segmented {
                switch networkPdu.type {
                case .accessMessage:
                    if let segment = SegmentedAccessMessage(fromSegmentPdu: networkPdu) {
                        logger?.d(.lowerTransport, "\(segment) received (decrypted using key: \(segment.networkKey))")
                        if let pdu = assemble(segment: segment, createdFrom: networkPdu) {
                            return .success(.lowerTransportPdu(pdu))
                        }
                    }
                case .controlMessage:
                    if let segment = SegmentedControlMessage(fromSegment: networkPdu) {
                        logger?.d(.lowerTransport, "\(segment) received (decrypted using key: \(segment.networkKey))")
                        if let pdu = assemble(segment: segment, createdFrom: networkPdu) {
                            return .success(.lowerTransportPdu(pdu))
                        }
                    }
                }
            } else {
                switch networkPdu.type {
                case .accessMessage:
                    if let accessMessage = AccessMessage(fromUnsegmentedPdu: networkPdu) {
                        logger?.i(.lowerTransport, "\(accessMessage) received (decrypted using key: \(accessMessage.networkKey))")
                        // Unsegmented message is not acknowledged. Just pass it to higher layer.
                        return .success(.lowerTransportPdu(accessMessage))
                    }
                case .controlMessage:
                    let opCode = networkPdu.transportPdu[0] & 0x7F
                    switch opCode {
                    case 0x00:
                        if let ack = SegmentAcknowledgmentMessage(fromNetworkPdu: networkPdu) {
                            logger?.d(.lowerTransport, "\(ack) received (decrypted using key: \(ack.networkKey))")
                            return .success(.acknowledgement(ack))
                        }
                    default:
                        if let controlMessage = ControlMessage(fromNetworkPdu: networkPdu) {
                            logger?.i(.lowerTransport, "\(controlMessage) received (decrypted using key: \(controlMessage.networkKey))")
                            // Unsegmented message is not acknowledged. Just pass it to higher layer.
                            return .success(.lowerTransportPdu(controlMessage))
                        }
                    }
                }
            }
            return .success(.none)
        }
        // Process the message on the original queue.
        switch try? result.get() {
        case .lowerTransportPdu(let pdu)?:
            networkManager.upperTransportLayer.handle(lowerTransportPdu: pdu)
        case .acknowledgement(let ack)?:
            handle(ack: ack)
        default:
            break
        }
    }
    
    /// This method tries to send the Upper Transport Message.
    ///
    /// - parameters:
    ///   - pdu:        The unsegmented Upper Transport PDU to be sent.
    ///   - initialTtl: The initial TTL (Time To Live) value of the message.
    ///                 If `nil`, the default Node TTL will be used.
    ///   - networkKey: The Network Key to be used to encrypt the message on
    ///                 on Network Layer.
    func send(unsegmentedUpperTransportPdu pdu: UpperTransportPdu,
              withTtl initialTtl: UInt8?,
              usingNetworkKey networkKey: NetworkKey) {
        guard let networkManager = networkManager,
              let provisionerNode = meshNetwork.localProvisioner?.node,
              let localElement = provisionerNode.element(withAddress: pdu.source) else {
            return
        }
        /// The Time To Live value.
        let ttl = initialTtl ?? provisionerNode.defaultTTL ?? networkManager.networkParameters.defaultTtl
        let message = AccessMessage(fromUnsegmentedUpperTransportPdu: pdu, usingNetworkKey: networkKey)
        do {
            logger?.i(.lowerTransport, "Sending \(message)")
            try networkManager.networkLayer.send(lowerTransportPdu: message, ofType: .networkPdu,
                                                 withTtl: ttl)
            networkManager.notifyAbout(deliveringMessage: pdu.message!,
                                       from: localElement, to: pdu.destination)
        } catch {
            logger?.w(.lowerTransport, error)
            if !pdu.message!.isAcknowledged {
                networkManager.notifyAbout(error: error, duringSendingMessage: pdu.message!,
                                           from: localElement, to: pdu.destination)
            }
        }
    }
    
    /// This method tries to send the Upper Transport Message.
    ///
    /// - parameters:
    ///   - pdu:        The segmented Upper Transport PDU to be sent.
    ///   - initialTtl: The initial TTL (Time To Live) value of the message.
    ///                 If `nil`, the default Node TTL will be used.
    ///   - networkKey: The Network Key to be used to encrypt the message on
    ///                 on Network Layer.
    func send(segmentedUpperTransportPdu pdu: UpperTransportPdu,
              withTtl initialTtl: UInt8?,
              usingNetworkKey networkKey: NetworkKey) {
        guard let networkManager = networkManager,
              let provisionerNode = meshNetwork.localProvisioner?.node else {
            return
        }
        /// Last 13 bits of the sequence number are known as seqZero.
        let sequenceZero = UInt16(pdu.sequence & 0x1FFF)
        /// Number of segments to be sent.
        let count = (pdu.transportPdu.count + 11) / 12
        
        // Create all segments to be sent.
        outgoingSegments[sequenceZero] = (pdu.destination, Array<SegmentedAccessMessage?>(repeating: nil, count: count))
        for i in 0..<count {
            outgoingSegments[sequenceZero]!.segments[i] = SegmentedAccessMessage(fromUpperTransportPdu: pdu,
                                                                                 usingNetworkKey: networkKey,
                                                                                 offset: UInt8(i))
        }
        segmentTtl[sequenceZero] = initialTtl ?? provisionerNode.defaultTTL ?? networkManager.networkParameters.defaultTtl
        sendSegments(for: sequenceZero, limit: networkManager.networkParameters.retransmissionLimit)
    }
    
    /// This method tries to send the Heartbeat Message.
    ///
    /// - parameters:
    ///   - heartbeat: The Heartbeat message to be sent.
    ///   - networkKey: The Network Key to be used to encrypt the message.
    func send(heartbeat: HeartbeatMessage, usingNetworkKey networkKey: NetworkKey) {
        guard let networkManager = networkManager else { return }
        let message = ControlMessage(fromHeartbeatMessage: heartbeat, usingNetworkKey: networkKey)
        do {
            logger?.i(.lowerTransport, "Sending \(message)")
            try networkManager.networkLayer.send(lowerTransportPdu: message, ofType: .networkPdu,
                                                 withTtl: heartbeat.initialTtl)
        } catch {
            logger?.w(.lowerTransport, error)
        }
    }
    
    /// Cancels sending segmented Upper Transport PDU.
    ///
    /// - parameter pdu: The Upper Transport PDU.
    func cancelSending(segmentedUpperTransportPdu pdu: UpperTransportPdu) {
        /// Last 13 bits of the sequence number are known as seqZero.
        let sequenceZero = UInt16(pdu.sequence & 0x1FFF)
        
        logger?.d(.lowerTransport, "Cancelling sending segments with seqZero: \(sequenceZero)")
        outgoingSegments.removeValue(forKey: sequenceZero)
        segmentTtl.removeValue(forKey: sequenceZero)
        segmentTransmissionTimers.removeValue(forKey: sequenceZero)?.invalidate()
    }
    
    /// Returns whether the Lower Transport Layer is in progress of
    /// receiving a segmented message from the given address.
    ///
    /// - parameter address: The source address.
    /// - returns: `True` is some, but not all packets of a segmented
    ///            message were received from the given source address;
    ///            `false` if no packets were received or the message
    ///            was complete before calling this method.
    func isReceivingMessage(from address: Address) -> Bool {
        return incompleteSegments.contains { entry in
            (entry.key >> 16) & 0xFFFF == UInt32(address)
        }
    }
    
}

private extension LowerTransportLayer {
    
    /// This method checks the given Network PDU against replay attacks.
    ///
    /// Unsegmented messages are checked against their sequence number.
    ///
    /// Segmented messages are checked against the SeqAuth value of the first
    /// segment of the message. Segments may be received in random order
    /// and unless the message SeqAuth is always greater, the replay attack
    /// is not possible.
    ///
    /// - important: Messages sent to a Unicast Address assigned to other Nodes
    ///              than the local one are not checked against reply attacks.
    ///
    /// - parameter networkPdu: The Network PDU to validate.
    func checkAgainstReplayAttack(_ networkPdu: NetworkPdu) -> Bool {
        // Don't check messages sent to other Nodes.
        guard !networkPdu.destination.isUnicast ||
              meshNetwork.localProvisioner?.node?.contains(elementWithAddress: networkPdu.destination) ?? false else {
            return true
        }
        let sequence = networkPdu.messageSequence
        let receivedSeqAuth = (UInt64(networkPdu.ivIndex) << 24) | UInt64(sequence)
        
        if let localSeqAuth = defaults.lastSeqAuthValue(for: networkPdu.source) {
            // In general, the SeqAuth of the received message must be greater
            // than SeqAuth of any previously received message from the same source.
            // However, for SAR (Segmentation and Reassembly) sessions, it is
            // the SeqAuth of the message, not segment, that is being checked.
            // If SAR is active (at least one segment for the same SeqAuth has
            // been previously received), the segments may be processed in any order.
            // The SeqAuth of this message must be greater or equal to the last one.
            var reassemblyInProgress = false
            if networkPdu.isSegmented {
                let sequenceZero = UInt16(sequence & 0x1FFF)
                let key = UInt32(keyFor: networkPdu.source, sequenceZero: sequenceZero)
                reassemblyInProgress = incompleteSegments[key] != nil ||
                                       acknowledgments[networkPdu.source]?.sequenceZero == sequenceZero
            }
            
            // As the messages are processed in a concurrent queue, it may happen that two
            // messages sent almost immediately were received in the right order, but are
            // processed in the opposite order. To handle that case, the previous SeqAuth
            // is stored. If the received message has SeqAuth less than the last one, but
            // greater than the previous one, it could not be used to replay attack, as no
            // message with that SeqAuth was ever received.
            //
            // Note: Only the single previous SeqAuth is stored, so if 3 or more messages are
            //       sent one after another, some of them still may be discarded despite being
            //       received in the correct order. As a workaround, the queue may be set to
            //       a serial one in MeshNetworkManager initializer.
            var missed = false
            if let previousSeqAuth = defaults.previousSeqAuthValue(for: networkPdu.source) {
                missed = receivedSeqAuth < localSeqAuth &&
                         receivedSeqAuth > previousSeqAuth
            }
            
            // Validate.
            guard receivedSeqAuth > localSeqAuth || missed ||
                  (reassemblyInProgress && receivedSeqAuth == localSeqAuth) else {
                // Ignore that message.
                logger?.w(.lowerTransport, "Discarding packet (seqAuth: \(receivedSeqAuth), expected > \(localSeqAuth))")
                return false
            }
            
            // The message is valid. Remember the previous SeqAuth.
            let newPreviousSeqAuth = min(receivedSeqAuth, localSeqAuth)
            defaults.storePreviousSeqAuthValue(newPreviousSeqAuth, for: networkPdu.source)
            
            // If the message was processed after its successor, don't overwrite the last SeqAuth.
            if missed {
                return true
            }
        }
        // SeqAuth is valid, save the new sequence authentication value.
        defaults.storeLastSeqAuthValue(receivedSeqAuth, for: networkPdu.source)
        return true
    }
    
    /// Handles the segment created from the given network PDU.
    ///
    /// - parameters:
    ///   - segment: The segment to handle.
    ///   - networkPdu: The Network PDU from which the segment was decoded.
    /// - returns: The Lower Transport PDU had it been fully assembled,
    ///            `nil` otherwise.
    func assemble(segment: SegmentedMessage, createdFrom networkPdu: NetworkPdu) -> LowerTransportPdu? {
        guard let networkManager = networkManager else { return nil }
        // If the received segment comes from an already completed and
        // acknowledged message, send the same ACK immediately.
        if let lastAck = acknowledgments[segment.source], lastAck.sequenceZero == segment.sequenceZero {
            if let provisionerNode = meshNetwork.localProvisioner?.node {
                logger?.d(.lowerTransport, "Message already acknowledged, sending ACK again")
                let ttl = networkPdu.ttl > 0 ? provisionerNode.defaultTTL ?? networkManager.networkParameters.defaultTtl : 0
                sendAck(lastAck, withTtl: ttl)
            } else {
                acknowledgments.removeValue(forKey: segment.source)
            }
            return nil
        }
        // Remove the last ACK. The source Node has sent a new message, so
        // the last ACK must have been received.
        acknowledgments.removeValue(forKey: segment.source)
        
        // A segmented message may be composed of 1 or more segments.
        if segment.isSingleSegment {
            let message = [segment].reassembled
            logger?.i(.lowerTransport, "\(message) received")
            // A single segment message may immediately be acknowledged.
            if let provisionerNode = meshNetwork.localProvisioner?.node,
               provisionerNode.contains(elementWithAddress: networkPdu.destination) {
                let ttl = networkPdu.ttl > 0 ? provisionerNode.defaultTTL ?? networkManager.networkParameters.defaultTtl : 0
                sendAck(for: [segment], withTtl: ttl)
            }
            return message
        } else {
            // If a message is composed of multiple segments, they all need to
            // be received before it can be processed.
            let key = UInt32(keyFor: networkPdu.source, sequenceZero: segment.sequenceZero)
            if incompleteSegments[key] == nil {
                incompleteSegments[key] = Array<SegmentedMessage?>(repeating: nil, count: segment.count)
            }
            guard incompleteSegments[key]!.count > segment.index else {
                // Segment is invalid. We can stop here.
                logger?.w(.lowerTransport, "Invalid segment")
                return nil
            }
            incompleteSegments[key]![segment.index] = segment
            
            // If all segments were received, send ACK and send the PDU to Upper
            // Transport Layer for processing.
            if incompleteSegments[key]!.isComplete {
                let allSegments = incompleteSegments.removeValue(forKey: key)!
                let message = allSegments.reassembled
                logger?.i(.lowerTransport, "\(message) received")
                // If the access message was targeting directly the local Provisioner...
                if let provisionerNode = meshNetwork.localProvisioner?.node,
                   provisionerNode.contains(elementWithAddress: networkPdu.destination) {
                    // ...invalidate timers...
                    incompleteTimers.removeValue(forKey: key)?.invalidate()
                    acknowledgmentTimers.removeValue(forKey: key)?.invalidate()
                    
                    // ...and send the ACK that all segments were received.
                    let ttl = networkPdu.ttl > 0 ? provisionerNode.defaultTTL ?? networkManager.networkParameters.defaultTtl : 0
                    sendAck(for: allSegments, withTtl: ttl)
                }
                return message
            } else {
                // The Provisioner shall send block acknowledgment only if the message was
                // send directly to it's Unicast Address.
                guard let provisionerNode = meshNetwork.localProvisioner?.node,
                      provisionerNode.contains(elementWithAddress: networkPdu.destination) else {
                    return nil
                }
                // If the Lower Transport Layer receives any segment while the incomplete
                // timer is active, the timer shall be restarted.
                incompleteTimers[key]?.invalidate()
                incompleteTimers[key] = BackgroundTimer.scheduledTimer(
                    withTimeInterval: networkManager.networkParameters.incompleteMessageTimeout, repeats: false, queue: self.mutex
                ) { [weak self] _ in
                    guard let self = self else { return }
                    if let segments = self.incompleteSegments.removeValue(forKey: key) {
                        var marks: UInt32 = 0
                        segments.forEach {
                            if let segment = $0 {
                                marks |= 1 << segment.segmentOffset
                            }
                        }
                        self.logger?.w(.lowerTransport, "Incomplete message timeout: cancelling message " +
                                                        "(src: \(Address(key >> 16).hex), seqZero: \(key & 0x1FFF), " +
                                                        "received segments: 0x\(marks.hex))")
                    }
                    self.incompleteTimers.removeValue(forKey: key)?.invalidate()
                    self.acknowledgmentTimers.removeValue(forKey: key)?.invalidate()
                }
                // If the Lower Transport Layer receives any segment while the acknowledgment
                // timer is inactive, it shall restart the timer. Active timer should not be restarted.
                if acknowledgmentTimers[key] == nil {
                    let ttl = provisionerNode.defaultTTL ?? networkManager.networkParameters.defaultTtl
                    let interval = networkManager.networkParameters.acknowledgmentTimerInterval(forTtl: ttl)
                    acknowledgmentTimers[key] = BackgroundTimer.scheduledTimer(
                        withTimeInterval: interval, repeats: false, queue: self.mutex
                    ) { [weak self] _ in
                        guard let self = self else { return }
                        if let segments = self.incompleteSegments[key] {
                            let ttl = networkPdu.ttl > 0 ? ttl : 0
                            self.sendAck(for: segments, withTtl: ttl)
                        }
                        self.acknowledgmentTimers.removeValue(forKey: key)?.invalidate()
                    }
                }
                return nil
            }
        }
    }
    
    /// This method handles the Segment Acknowledgment Message.
    ///
    /// - parameter ack: The Segment Acknowledgment Message received.
    func handle(ack: SegmentAcknowledgmentMessage) {
        guard let networkManager = networkManager else { return }
        // Ensure the ACK is for some message that has been sent.
        guard let (destination, segments) = outgoingSegments[ack.sequenceZero],
              let segment = segments.firstNotAcknowledged else {
            return
        }
        
        // Invalidate transmission timer for this message.
        segmentTransmissionTimers.removeValue(forKey: ack.sequenceZero)?.invalidate()
        
        // Find the source Element.
        guard let provisionerNode = meshNetwork.localProvisioner?.node,
              let element = provisionerNode.element(withAddress: segment.source) else {
            return
        }
        
        // Is the target Node busy?
        guard !ack.isBusy else {
            outgoingSegments.removeValue(forKey: ack.sequenceZero)
            if segment.userInitiated && !segment.message!.isAcknowledged {
                networkManager.notifyAbout(error: LowerTransportError.busy,
                                           duringSendingMessage: segment.message!,
                                           from: element, to: destination)
            }
            return
        }
        
        // Clear all acknowledged segments.
        for index in 0..<segments.count {
            if ack.isSegmentReceived(index) {
                outgoingSegments[ack.sequenceZero]?.segments[index] = nil
            }
        }
        
        // If all the segments were acknowledged, notify the manager.
        if outgoingSegments[ack.sequenceZero]?.segments.hasMore == false {
            outgoingSegments.removeValue(forKey: ack.sequenceZero)
            networkManager.notifyAbout(deliveringMessage: segment.message!,
                                       from: element, to: destination)
            networkManager.upperTransportLayer
                .lowerTransportLayerDidSend(segmentedUpperTransportPduTo: segment.destination)
        } else {
            // Else, send again all packets that were not acknowledged.
            sendSegments(for: ack.sequenceZero, limit: networkManager.networkParameters.retransmissionLimit)
        }
    }
    
    /// This method tries to send the Segment Acknowledgment Message to the
    /// given address. It will try to send if the local Provisioner is set and
    /// has the Unicast Address assigned.
    ///
    /// If the `transporter` throws an error during sending, this error will be ignored.
    ///
    /// - parameters:
    ///   - segments: The array of message segments, of which at least one
    ///               has to be not `nil`.
    ///   - ttl:      Initial Time To Live (TTL) value.
    func sendAck(for segments: [SegmentedMessage?], withTtl ttl: UInt8) {
        let ack = SegmentAcknowledgmentMessage(for: segments)
        if segments.isComplete {
            acknowledgments[ack.destination] = ack
        }
        sendAck(ack, withTtl: ttl)
    }
    
    /// Sends the given ACK on the global background queue.
    ///
    /// - parameters:
    ///   - ack: The Segment Acknowledgment Message to sent.
    ///   - ttl: Initial Time To Live (TTL) value.
    func sendAck(_ ack: SegmentAcknowledgmentMessage, withTtl ttl: UInt8) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let networkManager = self?.networkManager else { return }
            self?.logger?.d(.lowerTransport, "Sending \(ack)")
            do {
                try networkManager.networkLayer.send(lowerTransportPdu: ack,
                                                     ofType: .networkPdu, withTtl: ttl)
            } catch {
                self?.logger?.w(.lowerTransport, error)
            }
        }
    }
    
    /// Sends all non-`nil` segments from `outgoingSegments` map from the given
    /// `sequenceZero` key.
    ///
    /// - parameters:
    ///   - sequenceZero: The key to get segments from the map.
    ///   - limit:        Maximum number of retransmissions.
    func sendSegments(for sequenceZero: UInt16, limit: Int) {
        guard let networkManager = networkManager else { return }
        guard let (destination, segments) = outgoingSegments[sequenceZero], segments.count > 0,
              let segment = segments.firstNotAcknowledged,
              let message = segment.message,
              let ttl = segmentTtl[sequenceZero] else {
            return
        }
        
        // Find the source Element.
        guard let provisionerNode = meshNetwork.localProvisioner?.node,
              let element = provisionerNode.element(withAddress: segment.source) else {
            return
        }
        /// Segment Acknowledgment Message is expected when the message is targeting
        /// a Unicast Address.
        var ackExpected: Bool?
        
        // Send all the segments that have not been acknowledged yet.
        for i in 0..<segments.count {
            if let segment = segments[i] {
                do {
                    if ackExpected == nil {
                        ackExpected = segment.destination.isUnicast
                    }
                    logger?.d(.lowerTransport, "Sending \(segment)")
                    try networkManager.networkLayer.send(lowerTransportPdu: segment,
                                                         ofType: .networkPdu, withTtl: ttl)
                } catch {
                    logger?.w(.lowerTransport, error)
                    // Sending a segment failed.
                    if !ackExpected! {
                        segmentTransmissionTimers.removeValue(forKey: sequenceZero)?.invalidate()
                        outgoingSegments.removeValue(forKey: sequenceZero)
                        if segment.userInitiated && !message.isAcknowledged {
                            networkManager.notifyAbout(error: error, duringSendingMessage: message,
                                                       from: element, to: destination)
                        }
                        networkManager.upperTransportLayer
                            .lowerTransportLayerDidSend(segmentedUpperTransportPduTo: segment.destination)
                        return
                    }
                }
            }
        }
        // It is recommended to send all Lower Transport PDUs that are being sent
        // to a Group or Virtual Address multiple times, introducing small random
        // delays between repetitions. The specification does not say what small
        // random delay is, so assuming 0.5-1.5 second.
        if !ackExpected! {
            let interval = TimeInterval.random(in: 0.500...1.500)
            BackgroundTimer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
                guard let self = self,
                      let networkManager = self.networkManager else { return }
                var destination: Address?
                for i in 0..<segments.count {
                    if let segment = segments[i] {
                        if destination == nil {
                            destination = segment.destination
                        }
                        self.logger?.d(.lowerTransport, "Sending \(segment)")
                        do {
                            try networkManager.networkLayer.send(lowerTransportPdu: segment,
                                                                 ofType: .networkPdu, withTtl: ttl)
                        } catch {
                            self.logger?.w(.lowerTransport, error)
                        }
                    }
                }
                if let destination = destination {
                    networkManager.upperTransportLayer
                        .lowerTransportLayerDidSend(segmentedUpperTransportPduTo: destination)
                }
            }
        }
        
        segmentTransmissionTimers.removeValue(forKey: sequenceZero)?.invalidate()
        if ackExpected ?? false, let (destination, segments) = outgoingSegments[sequenceZero], segments.hasMore {
            if limit > 0 {
                let interval = networkManager.networkParameters.transmissionTimerInterval(forTtl: ttl)
                segmentTransmissionTimers[sequenceZero] =
                    BackgroundTimer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
                        self?.sendSegments(for: sequenceZero, limit: limit - 1)
                    }
            } else {
                // A limit has been reached and some segments were not ACK.
                if segment.userInitiated && !message.isAcknowledged {
                    networkManager.notifyAbout(error: LowerTransportError.timeout,
                                               duringSendingMessage: message,
                                               from: element, to: destination)
                }
                networkManager.upperTransportLayer
                    .lowerTransportLayerDidSend(segmentedUpperTransportPduTo: segment.destination)
                outgoingSegments.removeValue(forKey: sequenceZero)
            }
        } else {
            // All segments have been successfully sent to a Group Address.
            networkManager.notifyAbout(deliveringMessage: message,
                                       from: element, to: destination)
            outgoingSegments.removeValue(forKey: sequenceZero)
        }
    }
}

private extension UInt32 {
    
    /// The key used in maps in Lower Transport Layer to keep
    /// segments received to or from given source address.
    init(keyFor address: Address, sequenceZero: UInt16) {
        self = (UInt32(address) << 16) | UInt32(sequenceZero & 0x1FFF)
    }
    
}

private extension NetworkPdu {
    
    /// Whether the Network PDU contains a segmented Lower Transport PDU,
    /// or not.
    var isSegmented: Bool {
        return transportPdu[0] & 0x80 > 1
    }
    
    /// The 24-bit message sequence number used to transmit the first segment
    /// of a segmented message, or the 24-bit sequence number of an unsegmented
    /// message. This should be prefixed with 32-bit IV Index to get Seeq Auth.
    ///
    /// If the Seq is 0x647262 and SeqZero is 0x1849, the message sequence
    /// should be 0x6451849. See Bluetooth Mesh Profile 1.0.1 chapter 3.5.3.1.
    var messageSequence: UInt32 {
        if isSegmented {
            let sequenceZero = (UInt16(transportPdu[1] & 0x7F) << 6) | UInt16(transportPdu[2] >> 2)
            if (sequence & 0x1FFF < sequenceZero) {
                return (sequence & 0xFFE000) + UInt32(sequenceZero) - (0x1FFF + 1)
            } else {
                return (sequence & 0xFFE000) + UInt32(sequenceZero)
            }
        } else {
            return sequence
        }
    }
    
}

private extension Array where Element == SegmentedMessage? {
    
    /// Returns whether all the segments were received.
    var isComplete: Bool {
        return !contains { $0 == nil }
    }
    
    /// Returns whether some segments were not yet acknowledged.
    var hasMore: Bool {
        return contains { $0 != nil }
    }
    
    /// Returns the first not yet acknowledged segment.
    var firstNotAcknowledged: SegmentedMessage? {
        return first { $0 != nil }!
    }
    
    /// Converts the list of segments into either an `AccessMessage`,
    /// or a `ControlMessage`, depending on the first element type.
    ///
    /// All the segments in the Array must not be `nil`.
    var reassembled: LowerTransportPdu {
        if self[0] is SegmentedAccessMessage {
            return AccessMessage(fromSegments: self as! [SegmentedAccessMessage])
        } else {
            return ControlMessage(fromSegments: self as! [SegmentedControlMessage])
        }
    }
    
}
