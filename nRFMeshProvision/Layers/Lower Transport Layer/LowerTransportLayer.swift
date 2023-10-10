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
    ///
    /// This error is not propagated to higher levels. When it is caught, the received packet discarded.
    case replayAttack
}

internal class LowerTransportLayer {
    private weak var networkManager: NetworkManager?
    private let meshNetwork: MeshNetwork
    private let mutex = DispatchQueue(label: "LowerTransportLayerMutex")
    
    private var logger: LoggerDelegate? {
        return networkManager?.logger
    }
    
    /// The storage for keeping sequence numbers.
    ///
    /// Each mesh network (with different UUID) has a unique storage, which can be reloaded
    /// when the network is imported after it was used before.
    private let defaults: UserDefaults
    
    // MARK: - SAR Receiver
    
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
    /// The map of active SAR Discard Timers.
    ///
    /// The time is initially set to ``NetworkParameters/discardTimeout`` seconds.
    /// It resets every time a new segment of a segmented message is received and
    /// is cancelled when the last segment is received. When the timer times out, the
    /// message is cancelled and all received segments are deleted.
    ///
    /// The key consists of 16 bits of source address in 2 most significant bytes
    /// and `sequenceZero` field in 13 least significant bits.
    /// See `UInt32(keyFor:sequenceZero)` below.
    private var discardTimers: [UInt32 : BackgroundTimer]
    /// The map of active SAR Acknowledgment timers.
    ///
    /// After receiving a segment targeting the Unicast Addresses of any of the Elements
    /// of the local Node, a timer is started that will send the Segment Acknowledgment Message
    /// acknowledging segments received until that time. The timer is invalidated when the message
    /// has been completed or cancelled.
    ///
    /// When a segment of an already received message is received this timer is started
    /// to ensure the acknowledgments are not sent too often.
    ///
    /// The key consists of 16 bits of source address in 2 most significant bytes
    /// and `sequenceZero` field in 13 least significant bits.
    /// See `UInt32(keyFor:sequenceZero)` below.
    private var acknowledgmentTimers: [UInt32 : BackgroundTimer]
    
    // MARK: - SAR Transmitter
    
    /// The map of outgoing segmented messages.
    ///
    /// The key is the `sequenceZero` of the message.
    private var outgoingSegments: [UInt16: (destination: MeshAddress, segments: [SegmentedMessage?])]
    /// The map of SAR Unicast Retransmissions timers.
    ///
    /// The key of the map is the `sequenceZero` of a segmented message that is being sent
    /// to a Unicast Address.
    private var unicastRetransmissionsTimers: [UInt16 : BackgroundTimer]
    /// The map contains the number of remaining retransmissions and the number
    /// of remaininig retransmissions without progress of a segmented message
    /// that is sent to a Unicast Address.
    ///
    /// The number of retransmissions without progress is reset to its initial value each time a
    /// Segment Acknowledgment message indicating a progress in receiving segments is received.
    ///
    /// The transmission is cancelled with a timeout when any of the counters reaches zero.
    private var remainingNumberOfUnicastRetransmissions: [UInt16 : (total: UInt8, withoutProgress: UInt8)]
    
    /// The map of SAR Multicast Retransmissions timers.
    ///
    /// The key is the `sequenceZero` of the message.
    private var multicastRetransmissionsTimers: [UInt16 : BackgroundTimer]
    /// The map contains the number of remaining retransmissions of a segmented message
    /// that is sent to a Group Address or a Virtual Address.
    ///
    /// The transmission is completed when the counter reaches zero.
    private var remainingNumberOfMulticastRetransmissions: [UInt16 : UInt8]
    /// The initial TTL values.
    ///
    /// The key is the `sequenceZero` of the message.
    private var segmentTtl: [UInt16 : UInt8]
    
    init(_ networkManager: NetworkManager) {
        self.networkManager = networkManager
        self.meshNetwork = networkManager.meshNetwork
        self.defaults = UserDefaults(suiteName: meshNetwork.uuid.uuidString)!
        self.incompleteSegments = [:]
        self.discardTimers = [:]
        self.acknowledgmentTimers = [:]
        self.outgoingSegments = [:]
        self.unicastRetransmissionsTimers = [:]
        self.multicastRetransmissionsTimers = [:]
        self.remainingNumberOfUnicastRetransmissions = [:]
        self.remainingNumberOfMulticastRetransmissions = [:]
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
                
        // Segmented messages must be validated and assembled in a thread safe way.
        let result: Result<Message, Error> = mutex.sync {
            guard checkAgainstReplayAttack(networkPdu) else {
                return .failure(SecurityError.replayAttack)
            }

            // Lower Transport layer can receive Unsegmented or Segmented messages.
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
        // Store the TTL with which the segments are to be sent.
        segmentTtl[sequenceZero] = initialTtl ?? provisionerNode.defaultTTL ?? networkManager.networkParameters.defaultTtl
        // Initialize the retransmission counters.
        if pdu.destination.address.isUnicast {
            remainingNumberOfUnicastRetransmissions[sequenceZero] = (
                networkManager.networkParameters.sarUnicastRetransmissionsCount,
                networkManager.networkParameters.sarMulticastRetransmissionsCount
            )
        } else {
            remainingNumberOfMulticastRetransmissions[sequenceZero] =
                networkManager.networkParameters.sarMulticastRetransmissionsCount
        }
        // Finally, start sending segments.
        sendSegments(for: sequenceZero)
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
        unicastRetransmissionsTimers.removeValue(forKey: sequenceZero)?.invalidate()
        remainingNumberOfUnicastRetransmissions.removeValue(forKey: sequenceZero)
        multicastRetransmissionsTimers.removeValue(forKey: sequenceZero)?.invalidate()
        remainingNumberOfMulticastRetransmissions.removeValue(forKey: sequenceZero)
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
            //       received in the correct order.
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
        
        let key = UInt32(keyFor: networkPdu.source, sequenceZero: segment.sequenceZero)
        
        // If the received segment comes from an already completed and
        // acknowledged message, send the same ACK immediately.
        if let lastAck = acknowledgments[segment.source], lastAck.sequenceZero == segment.sequenceZero {
            if let provisionerNode = meshNetwork.localProvisioner?.node {
                // The lower transport layer shall not send more than one
                // Segment Acknowledgment message for the same SeqAuth in a
                // period of `completeAcknowledgementTimerInterval`.
                guard acknowledgmentTimers[key] == nil else {
                    logger?.d(.lowerTransport, "Message already acknowledged, ACK sent recently")
                    return nil
                }
                acknowledgmentTimers[key] = BackgroundTimer.scheduledTimer(
                    withTimeInterval: networkManager.networkParameters.completeAcknowledgmentTimerInterval, repeats: false
                ) { [weak self] _ in
                    // Until this timer is not executed no Segment Acknowledgment Message
                    // will be sent for the same completed message.
                    self?.acknowledgmentTimers.removeValue(forKey: key)?.invalidate()
                }
                // Now we're sure that the ACK has not been sent in a while.
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
                    discardTimers.removeValue(forKey: key)?.invalidate()
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
                // If the Lower Transport Layer receives any segment while the SAR Discard Timer
                // is active, the timer shall be restarted.
                discardTimers[key]?.invalidate()
                discardTimers[key] = BackgroundTimer.scheduledTimer(
                    withTimeInterval: networkManager.networkParameters.discardTimeout, repeats: false, queue: self.mutex
                ) { [weak self] _ in
                    guard let self = self else { return }
                    if let segments = self.incompleteSegments.removeValue(forKey: key) {
                        var marks: UInt32 = 0
                        segments.forEach {
                            if let segment = $0 {
                                marks |= 1 << segment.segmentOffset
                            }
                        }
                        self.logger?.w(.lowerTransport, "Discard timeout expired, cancelling message " +
                                                        "(src: \(Address(key >> 16).hex), seqZero: \(key & 0x1FFF), " +
                                                        "received segments: 0x\(marks.hex))")
                    }
                    self.discardTimers.removeValue(forKey: key)?.invalidate()
                    self.acknowledgmentTimers.removeValue(forKey: key)?.invalidate()
                }
                // When a segment is received the SAR Acknowledgment timer shall be (re)started.
                acknowledgmentTimers[key]?.invalidate()
                
                let ttl = provisionerNode.defaultTTL ?? networkManager.networkParameters.defaultTtl
                let interval = networkManager.networkParameters.acknowledgmentTimerInterval(forLastSegmentNumber: segment.lastSegmentNumber)
                acknowledgmentTimers[key] = BackgroundTimer.scheduledTimer(
                    withTimeInterval: interval, repeats: false, queue: self.mutex
                ) { [weak self] _ in
                    guard let s = self,
                          let networkManager = s.networkManager else { return }
                    guard let segments = s.incompleteSegments[key] else {
                        s.acknowledgmentTimers.removeValue(forKey: key)
                        return
                    }
                    // When the SAR Acknowledgment timer expires, the lower transport
                    // layer shall send a Segment Acknowledgment message.
                    let ttl = networkPdu.ttl > 0 ? ttl : 0
                    s.logger?.d(.lowerTransport, "SAR Acknowledgment timer expired, sending ACK")
                    s.sendAck(for: segments, withTtl: ttl)
                    
                    // If Segment Acknowledgment retransmission is enabled and the
                    // number of segments of the segmented message is longer than the
                    // SAR Segments Threshold, the lower transport layer should retransmit
                    // the acknowledgment specified number of times.
                    let initialCount = networkManager.networkParameters.sarAcknowledgmentRetransmissionsCount
                    var count = initialCount
                    if count > 0 &&
                        segment.lastSegmentNumber >= networkManager.networkParameters.sarSegmentsThreshold {
                        let interval = networkManager.networkParameters.segmentReceptionInterval
                        s.acknowledgmentTimers[key] = BackgroundTimer.scheduledTimer(
                            withTimeInterval: interval, repeats: count > 1, queue: s.mutex
                        ) { [weak self] retransmissionTimer in
                            guard let s = self else { return }
                            // The Segment Acknowledgment message shall be retransmitted with a new SEQ number.
                            s.logger?.d(.lowerTransport, "Retransmitting ACK (\(1 + initialCount - count)/\(initialCount))")
                            s.sendAck(for: segments, withTtl: ttl)
                            // Decrement the counter.
                            count = count - 1
                            // Stop retransmissions when the counter has reached 0.
                            if count == 0 {
                                retransmissionTimer.invalidate()
                                s.acknowledgmentTimers.removeValue(forKey: key)
                            }
                        }
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
        // Ensure the ACK is for some message that has been sent.
        guard let networkManager = networkManager,
              let (destination, segments) = outgoingSegments[ack.sequenceZero],
              ack.source == destination.address || ack.isOnBehalfOfLowPowerNode,
              let (total, withProgress) = remainingNumberOfUnicastRetransmissions[ack.sequenceZero],
              let segment = segments.firstNotAcknowledged,
              let message = segment.message else {
            return
        }
        
        // Is the target Node busy?
        guard !ack.isBusy else {
            finalize(transmissionOfSegmentedMessageTo: destination,
                     withSeqZero: ack.sequenceZero)
            notifyAbout(completingSending: message,
                        from: segment.source, to: destination,
                        error: LowerTransportError.busy)
            return
        }
        
        /// Whether a progress has been made since the previous ACK.
        var progress = false
        
        // Clear all acknowledged segments.
        for index in 0..<segments.count {
            if ack.isSegmentReceived(index) {
                if outgoingSegments[ack.sequenceZero]?.segments[index] != nil {
                    progress = true
                    outgoingSegments[ack.sequenceZero]?.segments[index] = nil
                }
            }
        }
        
        // If all the segments were acknowledged, notify the manager.
        if outgoingSegments[ack.sequenceZero]?.segments.hasMore == false {
            self.finalize(transmissionOfSegmentedMessageTo: destination,
                          withSeqZero: ack.sequenceZero)
            self.notifyAbout(completingSending: message,
                             from: segment.source, to: destination)
        } else {
            // Check if the SAR Unicast Retransmission timer is running.
            guard let _ = unicastRetransmissionsTimers[ack.sequenceZero] else {
                // If not, that means that the segments are just being retransmitted
                // and we're done here. We shall receive a new acknowledgment in a bit.
                return
            }
            // Check if more retransmissions are possible.
            guard total > 0 && withProgress > 0 else {
                // If not, the running SAR Unicast Retransmissions timer will cancel
                // the message when it expires. Perhaps another acknowledgment will
                // be received before acknowledging all segments.
                return
            }
            // Stop the SAR Unicast Retransmissions timer.
            unicastRetransmissionsTimers.removeValue(forKey: ack.sequenceZero)?.invalidate()
            // Decrement the counters.
            // If a progress has been made, reset the remaining number of
            // retransmissions with progress to its initial value.
            remainingNumberOfUnicastRetransmissions[ack.sequenceZero] = (
                total - 1,
                progress ? networkManager.networkParameters.sarUnicastRetransmissionsWithoutProgressCount : withProgress - 1
            )
            // Lastly, send again all packets that were not acknowledged.
            sendSegments(for: ack.sequenceZero)
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
    
    /// Sends all unacknowledged segments with the given `sequenceZero` and starts
    /// a retransmissions timer.
    ///
    /// - note: This is an asynchronous method, It will initiate sending the remaining segments
    ///         and finish immediately.
    ///
    /// - parameter sequenceZero: The key to get segments from the map.
    func sendSegments(for sequenceZero: UInt16) {
        guard let (destination, segments) = outgoingSegments[sequenceZero], segments.count > 0 else {
            return
        }
        
        /// The list of segments to be sent.
        ///
        /// The list contains only unacknowledged segments. Acknowledge segments are
        /// set to `nil` when the Segment Acknowledgment message is received.
        ///
        /// - note: When the destination is a Group or Virtual Address there are no
        ///         acknowledgments, in which case all segments are unacknowledged.
        let remainingSegments = segments.unacknowledged
        
        Task.detached { [weak self] in
            await self?.sendSegments(remainingSegments)
            
            // When the last remaining segment has been sent, the lower transport
            // layer should start the SAR Unicast Retransmissions timer or the
            // SAR Multicast Retransmissions timer.
            if destination.address.isUnicast {
                self?.startUnicastRetransmissionsTimer(for: sequenceZero)
            } else {
                self?.startMulticastRetransmissionsTimer(for: sequenceZero)
            }
        }
    }
    
    /// Sends the given segments one by one with an interval determined by the segment
    /// transmission interval.
    ///
    /// - parameter segments: List of segments to be sent.
    func sendSegments(_ segments: [SegmentedMessage]) async {
        // The interval with which segments are sent by the lower transport layer.
        guard let segmentTransmissionInterval = networkManager?.networkParameters.segmentTransmissionInterval else {
            return
        }
        
        // Start sending segments in the same order as they are in the list.
        // Note: Each segment is sent with a delay, therefore each time we
        //       check if the network manager still exists.
        for segment in segments {
            // Make sure the network manager is alive.
            guard let networkManager = self.networkManager,
                  let networkLayer = networkManager.networkLayer else {
                return
            }
            // Make sure all the segments were not already acknowledged.
            // The this will turn nil when all segments were acknowledged.
            guard let ttl = segmentTtl[segment.sequenceZero] else {
                return
            }
            // Send the segment and wait the segment transmission interval.
            do {
                self.logger?.d(.lowerTransport, "Sending \(segment)")
                try networkLayer.send(lowerTransportPdu: segment,
                                      ofType: .networkPdu, withTtl: ttl)
                try await Task.sleep(seconds: segmentTransmissionInterval)
            } catch {
                self.logger?.w(.lowerTransport, error)
                break
            }
        }
    }
    
    /// Starts the SAR Unicast Retransmissions timer for the message with given
    /// `sequenceZero`.
    ///
    /// If the remaining number of retransmissions and the remaining number of
    /// retransmissions without progress must be set before the timer is started.
    ///
    /// - parameter sequenceZero: The key to get segments from the map.
    func startUnicastRetransmissionsTimer(for sequenceZero: UInt16) {
        guard let networkManager = networkManager,
              let remainingNumberOfUnicastRetransmissions = remainingNumberOfUnicastRetransmissions[sequenceZero],
              let (destination, segments) = outgoingSegments[sequenceZero],
              let segment = segments.firstNotAcknowledged,
              let message = segment.message,
              let ttl = segmentTtl[sequenceZero] else {
            return
        }
        /// Remaining number of retransmissions of segments of an segmented message
        /// sent to a Unicast Address. When the number goes to 0 the retransmissions stop.
        let remainingNumberOfRetransmissions = remainingNumberOfUnicastRetransmissions.total
        /// Remaining number of retransmissions without progress of segments of an segmented
        /// message sent to a Unicast Address. When the number goes to 0 the retransmissions stop.
        let remainingNumberOfRetransmissionsWithoutProgress = remainingNumberOfUnicastRetransmissions.withoutProgress
        
        /// The initial value of the SAR Unicast Retransmissions timer.
        let interval = networkManager.networkParameters.unicastRetransmissionsInterval(for: ttl)
        
        // Start the SAR Unicast Retransmissions timer.
        unicastRetransmissionsTimers[sequenceZero] = BackgroundTimer.scheduledTimer(
            withTimeInterval: interval, repeats: false, queue: mutex
        ) { [weak self] _ in
            guard let self = self else { return }
            // The timer has expired, remove it.
            self.unicastRetransmissionsTimers.removeValue(forKey: sequenceZero)
            
            // When the SAR Unicast Retransmissions timer expires and either the remaining
            // number of retransmissions or the remaining number of retransmissions without progress is 0,
            // the lower transport layer shall cancel the transmission of the Upper Transport PDU,
            // shall delete the number of retransmissions value and the number of retransmissions without progress value,
            // shall remove the destination address and the SeqAuth stored for this segmented message,
            // and shall notify the upper transport layer that the transmission of the Upper Transport PDU has timed out.
            guard remainingNumberOfRetransmissions > 0 && remainingNumberOfRetransmissionsWithoutProgress > 0 else {
                self.finalize(transmissionOfSegmentedMessageTo: destination,
                              withSeqZero: sequenceZero)
                
                // Notify the user about a timeout only if sending the message was initiated
                // by the user (that means it is not sent as an automatic response to a
                // acknowledged request) and if the message is not acknowledged
                // (in which case the Access Layer may retry).
                if segment.userInitiated && !message.isAcknowledged {
                    self.notifyAbout(completingSending: message,
                                     from: segment.source, to: destination, 
                                     error: LowerTransportError.timeout)
                }
                return
            }
            // Decrement both counters. As the SAR Unicast Retransmission timer
            // has expired, no progress has been made.
            self.remainingNumberOfUnicastRetransmissions[sequenceZero] = (
                remainingNumberOfRetransmissions - 1,
                remainingNumberOfRetransmissionsWithoutProgress - 1
            )
            // Send again unacknowledged segments and restart the timer.
            self.sendSegments(for: sequenceZero)
        }
    }
    
    /// Starts the SAR Multicast Retransmissions timer for the message with given
    /// `sequenceZero`.
    ///
    /// If the remaining number of retransmissions must be set before the timer is started.
    ///
    /// - parameter sequenceZero: The key to get segments from the map.
    func startMulticastRetransmissionsTimer(for sequenceZero: UInt16) {
        guard let networkManager = networkManager,
              let remainingNumberOfRetransmissions = remainingNumberOfMulticastRetransmissions[sequenceZero],
              let (destination, segments) = outgoingSegments[sequenceZero],
              let segment = segments.firstNotAcknowledged,
              let message = segment.message else {
            return
        }
        
        /// The initial value of the SAR Multicast Retransmissions timer.
        let interval = networkManager.networkParameters.multicastRetransmissionsInterval
        
        // Start the SAR Multicast Retransmissions timer.
        multicastRetransmissionsTimers[sequenceZero] = BackgroundTimer.scheduledTimer(
            withTimeInterval: interval, repeats: false, queue: mutex
        ) { [weak self] _ in
            guard let self = self else { return }
            // The timer has expired, remove it.
            self.multicastRetransmissionsTimers.removeValue(forKey: sequenceZero)
            
            // When the SAR Multicast Retransmissions timer expires and the remaining
            // number of retransmissions value is 0, the lower transport layer shall
            // cancel the transmission of the Upper Transport PDU, shall delete the number
            // of retransmissions value and the number of retransmissions without progress value,
            // shall remove the destination address stored for this segmented message,
            // and shall notify the higher layer that the transmission of the Upper Transport PDU
            // has been completed.
            guard remainingNumberOfRetransmissions > 0 else {
                self.finalize(transmissionOfSegmentedMessageTo: destination,
                              withSeqZero: sequenceZero)
                self.notifyAbout(completingSending: message, 
                                 from: segment.source, to: destination)
                return
            }
            // Decrement the counter.
            self.remainingNumberOfMulticastRetransmissions[sequenceZero] = remainingNumberOfRetransmissions - 1
            // Send again all segments and restart the timer.
            self.sendSegments(for: sequenceZero)
        }
    }
    
    /// Removes remaining segments and counters associated with the message with the
    /// given `sequenceZero`.
    ///
    /// - parameters:
    ///   - destination: The target address of the message.
    ///   - sequenceZero: The key to get segments from the map.
    func finalize(transmissionOfSegmentedMessageTo destination: MeshAddress,
                  withSeqZero sequenceZero: UInt16) {
        guard let networkManager = networkManager else {
            return
        }
        
        remainingNumberOfUnicastRetransmissions.removeValue(forKey: sequenceZero)
        remainingNumberOfMulticastRetransmissions.removeValue(forKey: sequenceZero)
        outgoingSegments.removeValue(forKey: sequenceZero)
        segmentTtl.removeValue(forKey: sequenceZero)
        
        networkManager.upperTransportLayer
            .lowerTransportLayerDidSend(segmentedUpperTransportPduTo: destination.address)
    }
    
    /// Notifies the `networkManager` about completing transfer of segmented
    /// message.
    ///
    /// The transfer could succeed or fail with an error.
    ///
    /// - parameters:
    ///   - message: The Access Layer message which was being sent.
    ///   - source: The Unicast Address of the source Element on the local Node.
    ///   - destination: The target address of the message.
    ///   - error: Optional error it transmission failed.
    func notifyAbout(completingSending message: MeshMessage,
                     from source: Address, to destination: MeshAddress,
                     error: Error? = nil) {
        guard let networkManager = networkManager else {
            return
        }
        // Find the source Element.
        guard let provisionerNode = meshNetwork.localProvisioner?.node,
              let element = provisionerNode.element(withAddress: source) else {
            return
        }
        if let error = error {
            networkManager.notifyAbout(error: error,
                                       duringSendingMessage: message,
                                       from: element, to: destination)
        } else {
            networkManager.notifyAbout(deliveringMessage: message,
                                       from: element, to: destination)
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
    /// message. This should be prefixed with 32-bit IV Index to get SeqAuth.
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
        return first { $0 != nil } ?? nil
    }
    
    /// Returns a list of unacknowledged segments.
    var unacknowledged: [SegmentedMessage] {
        return compactMap { $0 }
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
