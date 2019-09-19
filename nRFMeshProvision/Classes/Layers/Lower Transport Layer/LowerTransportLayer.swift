//
//  LowerTransportLayer.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 28/05/2019.
//

import Foundation

internal class LowerTransportLayer {
    private let networkManager: NetworkManager
    private let meshNetwork: MeshNetwork
    
    private var logger: LoggerDelegate? {
        return networkManager.manager.logger
    }
    
    /// The storage for keeping sequence numbers. Each mesh network (with different UUID)
    /// has a unique storage, which can be reloaded when the network is imported after it
    /// was used before.
    let defaults: UserDefaults
    
    /// The map of incomplete received segments. Every time a Segmented Message is received
    /// it is added to the map to an ordered array. When all segments are received
    /// they are sent for processing to higher layer.
    ///
    /// The key consists of 16 bits of source address in 2 most significant bytes
    /// and `sequenceZero` field in 13 least significant bits.
    /// See `UInt32(keyFor:segment)` below.
    var incompleteSegments: [UInt32 : [SegmentedMessage?]]
    /// This map contains Segment Acknowlegment Messages of completed messages.
    /// It is used when a complete Segmented Message has been received and the
    /// ACK has been sent but failed to reach the source Node.
    /// The Node would then resend all non-acknowledged segments and expect a new ACK.
    /// Without this map, this layer would have to complete again all segments in
    /// order to send the ACK. By checking if a segment comes from an already
    /// acknowledged message, it can immediatelly send the ACK again.
    ///
    /// An item is removed when a next message has been received from the same Node.
    var acknowledgments: [Address : SegmentAcknowledgmentMessage]
    /// The map of active timers. Every message has `defaultIncompleteTimerInterval`
    /// seconds to be completed (timer resets when next segment was received).
    /// After that time the segments are discarded.
    ///
    /// The key consists of 16 bits of source address in 2 most significant bytes
    /// and `sequenceZero` field in 13 least significant bits.
    /// See `UInt32(keyFor:sequenceZero)` below.
    var incompleteTimers: [UInt32 : BackgroundTimer]
    /// The map of acknowledgment timers. After receiving a segment targetting
    /// any of the Unicast Addresses of one of the Elements of the local Node, a
    /// timer is started that will send the Segment Acknowledgment Message for
    /// segments received until than. The timer is invalidated when the message
    /// has been completed.
    ///
    /// The key consists of 16 bits of source address in 2 most significant bytes
    /// and `sequenceZero` field in 13 least significant bits.
    /// See `UInt32(keyFor:sequenceZero)` below.
    var acknowledgmentTimers: [UInt32 : BackgroundTimer]
    
    /// The map of outgoing segmented messages.
    ///
    /// The key is the `sequenceZero` of the message.
    var outgoingSegments: [UInt16: [SegmentedMessage?]]
    /// The map of segment transmission timers. A segment transmission timer
    /// for a Segmented Message with `sequenceZero` is started whenever such
    /// message is sent to a Unicast Address. After the timer expires, the
    /// layer will resend all non-confirmed segments and reset the timer.
    ///
    /// The key is the `sequenceZero` of the message.
    var segmentTransmissionTimers: [UInt16 : BackgroundTimer]
    
    init(_ networkManager: NetworkManager) {
        self.networkManager = networkManager
        self.meshNetwork = networkManager.meshNetwork!
        self.defaults = UserDefaults(suiteName: meshNetwork.uuid.uuidString)!
        self.incompleteSegments = [:]
        self.incompleteTimers = [:]
        self.acknowledgmentTimers = [:]
        self.outgoingSegments = [:]
        self.segmentTransmissionTimers = [:]
        self.acknowledgments = [:]
    }
    
    /// This method handles the received Network PDU. If needed, it will reassembly
    /// the message, send block acknowledgment to the sender, and pass the Upper
    /// Transport PDU to the Upper Transport Layer.
    ///
    /// - parameter networkPdu: The Network PDU received.
    func handle(networkPdu: NetworkPdu) {
        // Some validation, just to be sure. This should pass for sure.
        guard networkPdu.transportPdu.count > 1 else {
            return
        }
        let newSource = defaults.object(forKey: networkPdu.source.hex) == nil
        if !newSource {
            // Check, if the sequence number is greater than the one used last
            // time by the source address.
            let lastSequence = defaults.integer(forKey: networkPdu.source.hex)
            let localSeqAuth = (UInt64(networkPdu.networkKey.ivIndex.index) << 24) | UInt64(lastSequence)
            let receivedSeqAuth = (UInt64(networkPdu.networkKey.ivIndex.index) << 24) | UInt64(networkPdu.sequence)
           
            guard receivedSeqAuth > localSeqAuth else {
                // Ignore that message.
                logger?.w(.lowerTransport, "Discarding packet (seqAuth: \(receivedSeqAuth), expected > \(localSeqAuth))")
                return
            }
        }
        // SeqAuth is valid, save the new sequence authentication value.
        defaults.set(networkPdu.sequence, forKey: networkPdu.source.hex)
        
        // Lower Transport Messages can be Unsegmented or Segmented.
        // This information is stored in the most significant bit of the first octet.
        let unsegmented = networkPdu.transportPdu[0] & 0x80 == 0
        
        // The Lower Transport Layer behaves differently based on the message type.
        switch networkPdu.type {
        case .accessMessage:
            if unsegmented {
                if let accessMessage = AccessMessage(fromUnsegmentedPdu: networkPdu) {
                    logger?.i(.lowerTransport, "\(accessMessage) receieved (decrypted using key: \(accessMessage.networkKey))")
                    // Unsegmented message is not acknowledged. Just pass it to higher layer.
                    networkManager.upperTransportLayer.handle(lowerTransportPdu: accessMessage)
                }
            } else {
                if let segment = SegmentedAccessMessage(fromSegmentPdu: networkPdu) {
                    logger?.d(.lowerTransport, "\(segment) receieved (decrypted using key: \(segment.networkKey))")
                    assemble(segment: segment, createdFrom: networkPdu)
                }
            }
        case .controlMessage:
            let opCode = networkPdu.transportPdu[0] & 0x7F
            switch opCode {
            case 0x00:
                if let ack = SegmentAcknowledgmentMessage(fromNetworkPdu: networkPdu) {
                    logger?.d(.lowerTransport, "\(ack) receieved (decrypted using key: \(ack.networkKey))")
                    handle(ack: ack)
                }
            default:
                if unsegmented {
                    if let controlMessage = ControlMessage(fromNetworkPdu: networkPdu) {
                        logger?.i(.lowerTransport, "\(controlMessage) receieved (decrypted using key: \(controlMessage.networkKey))")
                        // Unsegmented message is not acknowledged. Just pass it to higher layer.
                        networkManager.upperTransportLayer.handle(lowerTransportPdu: controlMessage)
                    }
                } else {
                    if let segment = SegmentedControlMessage(fromSegment: networkPdu) {
                        logger?.d(.lowerTransport, "\(segment) receieved (decrypted using key: \(segment.networkKey))")
                        assemble(segment: segment, createdFrom: networkPdu)
                    }
                }
            }
        }
    }
    
    /// This method tries to send the Upper Transport Message.
    ///
    /// - parameter pdu:         The Upper Transport PDU to be sent.
    /// - parameter isSegmented: `True` if the message should be sent as segmented, `false` otherwise.
    /// - parameter networkKey:  The Network Key to be used to encrypt the message on
    ///                          on Network Layer.
    func send(upperTransportPdu pdu: UpperTransportPdu, asSegmentedMessage isSegmented: Bool,
              usingNetworkKey networkKey: NetworkKey) {
        guard let provisionerNode = meshNetwork.localProvisioner?.node else {
            return
        }
        let ttl = provisionerNode.defaultTTL ?? networkManager.defaultTtl
        
        if isSegmented {
            let sequenceZero = UInt16(pdu.sequence & 0x1FFF)
            /// Number of segments to be sent.
            let count = (pdu.transportPdu.count + 11) / 12
            
            // Create all segments to be sent.
            outgoingSegments[sequenceZero] = Array<SegmentedAccessMessage?>(repeating: nil, count: count)
            for i in 0..<count {
                outgoingSegments[sequenceZero]![i] = SegmentedAccessMessage(fromUpperTransportPdu: pdu,
                                                                            usingNetworkKey: networkKey, offset: UInt8(i))
            }
            sendSegments(for: sequenceZero)
        } else {
            let message = AccessMessage(fromUnsegmentedUpperTransportPdu: pdu, usingNetworkKey: networkKey)
            do {
                logger?.i(.lowerTransport, "Sending \(message)")
                try networkManager.networkLayer.send(lowerTransportPdu: message, ofType: .networkPdu, withTtl: ttl)
                networkManager.notifyAbout(deliveringMessage: pdu.message!,
                                           from: pdu.localElement!, to: pdu.destination)
            } catch {
                logger?.w(.lowerTransport, error)
                networkManager.notifyAbout(error, duringSendingMessage: pdu.message!,
                                           from: pdu.localElement!, to: pdu.destination)
            }
        }
    }
    
}

private extension UInt32 {
    
    /// Returns the key used in maps in Lower Transport Layer to keep
    /// segments received to or from given source address.
    init(keyFor address: Address, sequenceZero: UInt16) {
        self = (UInt32(address) << 16) | UInt32(sequenceZero & 0x1FFF)
    }
    
}

private extension LowerTransportLayer {
    
    /// Handles the segment created from the given network PDU.
    ///
    /// - parameter segment: The segment to handle.
    /// - parameter networkPdu: The Network PDU from which the segment was decoded.
    func assemble(segment: SegmentedMessage, createdFrom networkPdu: NetworkPdu) {
        // If the received segment comes from an already completed and
        // acknowledged message, send the same ACK immediately.
        if let lastAck = acknowledgments[segment.source], lastAck.sequenceZero == segment.sequenceZero {
            if let provisionerNode = meshNetwork.localProvisioner?.node {
                logger?.d(.lowerTransport, "Message already acknowledged, sending ACK again")
                logger?.d(.lowerTransport, "Sending \(lastAck)")
                let ttl = networkPdu.ttl > 0 ? provisionerNode.defaultTTL ?? networkManager.defaultTtl : 0
                do {
                    try networkManager.networkLayer.send(lowerTransportPdu: lastAck, ofType: .networkPdu, withTtl: ttl)
                } catch {
                    logger?.w(.lowerTransport, error)
                }
            } else {
                acknowledgments.removeValue(forKey: segment.source)
            }
            return
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
                networkPdu.destination == provisionerNode.unicastAddress {
                let ttl = networkPdu.ttl > 0 ? provisionerNode.defaultTTL ?? networkManager.defaultTtl : 0
                sendAck(for: [segment], usingNetworkKey: networkPdu.networkKey, withTtl: ttl)
            }
            networkManager.upperTransportLayer.handle(lowerTransportPdu: message)
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
                return
            }
            incompleteSegments[key]![segment.index] = segment
            
            // If all segments were received, send ACK and send the PDU to Upper
            // Transport Layer for processing.
            if incompleteSegments[key]!.isComplete {
                let allSegments = incompleteSegments.removeValue(forKey: key)!
                let message = allSegments.reassembled
                logger?.i(.lowerTransport, "\(message) received")
                // If the access message was targetting directly the local Provisioner...
                if let provisionerNode = meshNetwork.localProvisioner?.node,
                    networkPdu.destination == provisionerNode.unicastAddress {
                    // ...invalidate timers...
                    incompleteTimers.removeValue(forKey: key)?.invalidate()
                    acknowledgmentTimers.removeValue(forKey: key)?.invalidate()
                    
                    // ...and send the ACK that all segments were received.
                    let ttl = networkPdu.ttl > 0 ? provisionerNode.defaultTTL ?? networkManager.defaultTtl : 0
                    sendAck(for: allSegments, usingNetworkKey: networkPdu.networkKey, withTtl: ttl)
                }
                networkManager.upperTransportLayer.handle(lowerTransportPdu: message)
            } else {
                // The Provisioner shall send block acknowledgment only if the message was
                // send directly to it's Unicast Address.
                guard let provisionerNode = meshNetwork.localProvisioner?.node,
                      networkPdu.destination == provisionerNode.unicastAddress else {
                    return
                }
                // If the Lower Transport Layer receives any segment while the incomplete
                // timer is active, the timer shall be restarted.
                incompleteTimers[key]?.invalidate()
                incompleteTimers[key] = BackgroundTimer.scheduledTimer(withTimeInterval: networkManager.incompleteMessageTimeout, repeats: false) { _ in
                    self.logger?.w(.lowerTransport, "Incomplete message timeout: cancelling message (src: \(Address(key >> 16).hex), seqZero: \(key & 0x1FFF))")
                    self.incompleteTimers.removeValue(forKey: key)?.invalidate()
                    self.acknowledgmentTimers.removeValue(forKey: key)?.invalidate()
                    self.incompleteSegments.removeValue(forKey: key)
                }
                // If the Lower Transport Layer receives any segment while the acknowlegment
                // timer is inactive, it shall restart the timer. Active timer should not be restarted.
                if acknowledgmentTimers[key] == nil {
                    let ttl = provisionerNode.defaultTTL ?? networkManager.defaultTtl
                    acknowledgmentTimers[key] = BackgroundTimer.scheduledTimer(withTimeInterval: networkManager.acknowledgmentTimerInterval(ttl), repeats: false) { _ in
                        let ttl = networkPdu.ttl > 0 ? ttl : 0
                        self.sendAck(for: self.incompleteSegments[key]!, usingNetworkKey: networkPdu.networkKey, withTtl: ttl)
                        self.acknowledgmentTimers.removeValue(forKey: key)?.invalidate()
                    }
                }
            }
        }
    }
    
    /// This method handles the Segment Acknowledgment Message.
    ///
    /// - parameter ack: The Segment Acknowledgment Message received.
    func handle(ack: SegmentAcknowledgmentMessage) {
        // Ensure the ACK is for some message that has been sent.
        guard outgoingSegments[ack.sequenceZero] != nil,
            let segment = outgoingSegments[ack.sequenceZero]!.firstNotAcknowledged else {
                return
        }
        
        // Invalidate transmission timer for this message.
        segmentTransmissionTimers.removeValue(forKey: ack.sequenceZero)?.invalidate()
        
        // Is the target Node busy?
        guard !ack.isBusy else {
            outgoingSegments.removeValue(forKey: ack.sequenceZero)
            networkManager.notifyAbout(LowerTransportError.busy,
                                       duringSendingMessage: segment.message!,
                                       from: segment.localElement!, to: segment.destination)
            return
        }
        
        // Clear all acknowledged segments.
        for index in 0..<outgoingSegments[ack.sequenceZero]!.count {
            if ack.isSegmentReceived(index) {
                outgoingSegments[ack.sequenceZero]![index] = nil
            }
        }
        
        // If all the segments were acknowledged, notify the manager.
        if !outgoingSegments[ack.sequenceZero]!.hasMore {
            outgoingSegments.removeValue(forKey: ack.sequenceZero)
            networkManager.notifyAbout(deliveringMessage: segment.message!,
                                       from: segment.localElement!, to: segment.destination)
        } else {
            // Else, send again all packets that were not acknowledged.
            sendSegments(for: ack.sequenceZero)
        }
    }
    
    /// This method tries to send the Segment Acknowledgment Message to the
    /// given address. It will try to send if the local Provisioner is set and
    /// has the Unicast Address assigned.
    ///
    /// If the `transporter` throws an error during sending, this error will be ignored.
    ///
    /// - parameter segments:   The array of message segments, of which at least one
    ///                         has to be not `nil`.
    /// - parameter networkKey: The Network Key to be used to encrypt the message on
    ///                         on Network Layer.
    /// - parameter ttl:        Initial Time To Live (TTL) value.
    func sendAck(for segments: [SegmentedMessage?], usingNetworkKey networkKey: NetworkKey, withTtl ttl: UInt8) {
        let ack = SegmentAcknowledgmentMessage(for: segments)
        if segments.isComplete {
            acknowledgments[ack.destination] = ack
        }
        logger?.d(.lowerTransport, "Sending \(ack)")
        do {
            try networkManager.networkLayer.send(lowerTransportPdu: ack, ofType: .networkPdu, withTtl: ttl)
        } catch {
            logger?.w(.lowerTransport, error)
        }
    }
    
    /// Sends all non-`nil` segments from `outgoingSegments` map from the given
    /// `sequenceZero` key.
    ///
    /// - parameter sequenceZero: The key to get segments from the map.
    func sendSegments(for sequenceZero: UInt16, limit: Int = 10) {
        guard let segments = outgoingSegments[sequenceZero], segments.count > 0,
              let provisionerNode = meshNetwork.localProvisioner?.node else {
            return
        }
        /// The default TTL of the local Node.
        let ttl = provisionerNode.defaultTTL ?? networkManager.defaultTtl
        /// Segment Acknowledgment Message is expected when the message is targetting
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
                    try networkManager.networkLayer.send(lowerTransportPdu: segment, ofType: .networkPdu, withTtl: ttl)
                } catch {
                    logger?.w(.lowerTransport, error)
                    // Sending a segment failed.
                    if !ackExpected! {
                        segmentTransmissionTimers.removeValue(forKey: sequenceZero)?.invalidate()
                        outgoingSegments.removeValue(forKey: sequenceZero)
                        networkManager.notifyAbout(error, duringSendingMessage: segment.message!,
                                                   from: segment.localElement!, to: segment.destination)
                        return
                    }
                }
            }
        }
        // It is recommended to send all Lower Transport PDUs that are being sent
        // to a Group or Virtual Address mutliple times, introducing small random
        // delays between repetitions. The specification does not say what small
        // random delay is, so assuming 0.5-1.5 second.
        if !ackExpected! {
            let interval = TimeInterval.random(in: 0.500...1.500)
            _ = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { timer in
                for i in 0..<segments.count {
                    if let segment = segments[i] {
                        self.logger?.d(.lowerTransport, "Sending \(segment)")
                        do {
                            try self.networkManager.networkLayer.send(lowerTransportPdu: segment,
                                                                      ofType: .networkPdu, withTtl: ttl)
                        } catch {
                            self.logger?.w(.lowerTransport, error)
                        }
                    }
                }
                timer.invalidate()
            }
        }
        
        segmentTransmissionTimers.removeValue(forKey: sequenceZero)?.invalidate()
        if ackExpected ?? false, let segments = outgoingSegments[sequenceZero], segments.hasMore {
            if limit > 0 {
                let interval = networkManager.transmissionTimerInteral(ttl)
                segmentTransmissionTimers[sequenceZero] =
                    BackgroundTimer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
                        self.sendSegments(for: sequenceZero, limit: limit - 1)
                    }
            } else {
                // A limit has been reached and some segments were not ACK.
                if let segment = segments.firstNotAcknowledged {
                    networkManager.notifyAbout(LowerTransportError.timeout,
                                               duringSendingMessage: segment.message!,
                                               from: segment.localElement!, to: segment.destination)
                }
                outgoingSegments.removeValue(forKey: sequenceZero)
            }
        } else {
            // All segments have been successfully sent to a Group Address.
            if let segment = segments.firstNotAcknowledged {
                networkManager.notifyAbout(deliveringMessage: segment.message!,
                                           from: segment.localElement!, to: segment.destination)
            }
            outgoingSegments.removeValue(forKey: sequenceZero)
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
