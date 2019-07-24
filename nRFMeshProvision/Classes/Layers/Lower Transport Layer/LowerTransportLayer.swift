//
//  LowerTransportLayer.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 28/05/2019.
//

import Foundation

internal class LowerTransportLayer {
    /// The Default TTL will be used for sending messages, if the value has not been
    /// set in the Provisioner's Node. It is set to 5, which is a reasonable value.
    /// If this value is not enough, make sure the default TTL value is set for the
    /// Provisioner.
    static let defaultTtl: UInt8 = 5
    /// The time after which an incomplete segmented message will be discarded, in seconds.
    let defaultIncompleteTimerInterval: TimeInterval = 10.0
    
    let networkManager: NetworkManager
    let meshNetwork: MeshNetwork
    
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
    var incompleteTimers: [UInt32 : Timer]
    /// The map of acknowledgment timers. After receiving a segment targetting
    /// any of the Unicast Addresses of one of the Elements of the local Node, a
    /// timer is started that will send the Segment Acknowledgment Message for
    /// segments received until than. The timer is invalidated when the message
    /// has been completed.
    ///
    /// The key consists of 16 bits of source address in 2 most significant bytes
    /// and `sequenceZero` field in 13 least significant bits.
    /// See `UInt32(keyFor:sequenceZero)` below.
    var acknowledgmentTimers: [UInt32 : Timer]
    
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
    var segmentTransmissionTimers: [UInt16 : Timer]
    
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
                print("Error: Received SeqAuth \(receivedSeqAuth) <= Local SeqAuth \(localSeqAuth)")
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
                    // Unsegmented message is not acknowledged. Just pass it to higher layer.
                    networkManager.upperTransportLayer.handle(lowerTransportPdu: accessMessage)
                }
            } else {
                if let segment = SegmentedAccessMessage(fromSegmentPdu: networkPdu) {
                    // A segmented message may be composed of 1 or more segments.
                    if segment.isSingleSegment {
                        // A single segment message may immediately be acknowledged.
                        if let provisionerNode = meshNetwork.localProvisioner?.node,
                            networkPdu.destination == provisionerNode.unicastAddress {
                            let ttl = networkPdu.ttl > 0 ? provisionerNode.defaultTTL ?? LowerTransportLayer.defaultTtl : 0
                            sendAck(for: [segment], usingNetworkKey: networkPdu.networkKey, withTtl: ttl)
                        }
                        let accessMessage = AccessMessage(fromSegments: [segment])
                        networkManager.upperTransportLayer.handle(lowerTransportPdu: accessMessage)
                    } else {
                        // If the received segment comes from an already completed and
                        // acknowledged message, send the same ACK immediatelly.
                        if let lastAck = acknowledgments[segment.source], lastAck.sequenceZero == segment.sequenceZero {
                            if let provisionerNode = meshNetwork.localProvisioner?.node {
                                let ttl = networkPdu.ttl > 0 ? provisionerNode.defaultTTL ?? LowerTransportLayer.defaultTtl : 0
                                try? networkManager.networkLayer.send(lowerTransportPdu: lastAck, ofType: .networkPdu, withTtl: ttl)
                            } else {
                                acknowledgments.removeValue(forKey: segment.source)
                            }
                            return
                        }
                        // Remove the last ACK. The source Node has sent a new message, so
                        // the last ACK must have been received.
                        acknowledgments.removeValue(forKey: segment.source)
                        
                        // If a message is composed of multiple segments, they all need to
                        // be received before it can be processed.
                        let key = UInt32(keyFor: networkPdu.source, sequenceZero: segment.sequenceZero)
                        if incompleteSegments[key] == nil {
                            incompleteSegments[key] = Array<SegmentedMessage?>(repeating: nil, count: segment.count)
                        }
                        guard incompleteSegments[key]!.count > segment.index && incompleteSegments[key]![segment.index] == nil else {
                            // Segment was sent again or it's invalid. We can stop here.
                            return
                        }
                        incompleteSegments[key]![segment.index] = segment
                        
                        // If all segments were received, send ACK and send the PDU to Upper
                        // Transport Layer for processing.
                        if incompleteSegments[key]!.isComplete {
                            let allSegments = incompleteSegments.removeValue(forKey: key)! as! [SegmentedAccessMessage]
                            // If the access message was targetting directly the local Provisioner...
                            if let provisionerNode = meshNetwork.localProvisioner?.node,
                                networkPdu.destination == provisionerNode.unicastAddress {
                                // ...invalidate timers...
                                incompleteTimers.removeValue(forKey: key)?.invalidate()
                                acknowledgmentTimers.removeValue(forKey: key)?.invalidate()
                                
                                // ...and send the ACK that all segments were received.
                                let ttl = networkPdu.ttl > 0 ? provisionerNode.defaultTTL ?? LowerTransportLayer.defaultTtl : 0
                                sendAck(for: allSegments, usingNetworkKey: networkPdu.networkKey, withTtl: ttl)
                            }
                            
                            let accessMessage = AccessMessage(fromSegments: allSegments)
                            networkManager.upperTransportLayer.handle(lowerTransportPdu: accessMessage)
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
                            incompleteTimers[key] = Timer.scheduledTimer(withTimeInterval: defaultIncompleteTimerInterval, repeats: false) { _ in
                                self.incompleteTimers.removeValue(forKey: key)?.invalidate()
                                self.acknowledgmentTimers.removeValue(forKey: key)?.invalidate()
                                self.incompleteSegments.removeValue(forKey: key)
                            }
                            // If the Lower Transport Layer receives any segment while the acknowlegment
                            // timer is inactive, it shall restart the timer. Active timer should not be restarted.
                            if acknowledgmentTimers[key] == nil {
                                let ttl = provisionerNode.defaultTTL ?? LowerTransportLayer.defaultTtl
                                acknowledgmentTimers[key] = Timer.scheduledTimer(withTimeInterval: 0.150 + Double(ttl) * 0.050, repeats: false) { _ in
                                    let ttl = networkPdu.ttl > 0 ? ttl : 0
                                    self.sendAck(for: self.incompleteSegments[key]!, usingNetworkKey: networkPdu.networkKey, withTtl: ttl)
                                    self.acknowledgmentTimers.removeValue(forKey: key)?.invalidate()
                                }
                            }
                        }
                    }
                }
            }
        case .controlMessage:
            let unsegmented = networkPdu.transportPdu[0] & 0x80 == 0
            let opCode = networkPdu.transportPdu[0] & 0x7F
            switch opCode {
            case 0x00:
                if let ack = SegmentAcknowledgmentMessage(fromNetworkPdu: networkPdu) {
                    guard outgoingSegments[ack.sequenceZero] != nil else {
                        return
                    }
                    for index in 0..<outgoingSegments[ack.sequenceZero]!.count {
                        if ack.isSegmentReceived(index) {
                            outgoingSegments[ack.sequenceZero]![index] = nil
                        }
                    }
                    
                    segmentTransmissionTimers.removeValue(forKey: ack.sequenceZero)?.invalidate()
                    if outgoingSegments[ack.sequenceZero]!.isComplete {
                        outgoingSegments.removeValue(forKey: ack.sequenceZero)
                    } else {
                        sendSegments(for: ack.sequenceZero)
                    }
                }
            default:
                if unsegmented {
                    if let controlMessage = ControlMessage(fromNetworkPdu: networkPdu) {
                        networkManager.upperTransportLayer.handle(lowerTransportPdu: controlMessage)
                    }
                } else {
                    if let segment = SegmentedControlMessage(fromSegment: networkPdu) {
                        // TODO: Finish implementation
                    }
                }
            }
        }
    }
    
    /// This method handles the Unprovisioned Device Beacon.
    ///
    /// The curernt implementation does nothing, as remote provisioning is
    /// currently not supported.
    ///
    /// - parameter unprovisionedDeviceBeacon: The Unprovisioned Device Beacon received.
    func handle(unprovisionedDeviceBeacon: UnprovisionedDeviceBeacon) {
        // Do nothing.
        // TODO: Handle Unprovisioned Device Beacon.
    }
    
    /// This method handles the Secure Network Beacon.
    /// It will set the proper IV Index and IV Update Active flag for the Network Key
    /// that matches Network ID and change the Key Refresh Phase based on the
    /// key refresh flag specified in the beacon.
    ///
    /// - parameter secureNetworkBeacon: The Secure Network Beacon received.
    func handle(secureNetworkBeacon: SecureNetworkBeacon) {
        if let networkKey = meshNetwork.networkKeys[secureNetworkBeacon.networkId] {
            networkKey.ivIndex = IvIndex(index: secureNetworkBeacon.ivIndex,
                                         updateActive: secureNetworkBeacon.ivUpdateActive)
            // If the Key Refresh Procedure is in progress, and the new Network Key
            // has already been set, the key erfresh flag indicates switching to phase 2.
            if case .distributingKeys = networkKey.phase, secureNetworkBeacon.keyRefreshFlag {
                networkKey.phase = .finalizing
            }
            // If the Key Refresh Procedure is in phase 2, and the key refresh flag is
            // set to false.
            if case .finalizing = networkKey.phase, !secureNetworkBeacon.keyRefreshFlag {
                networkKey.oldKey = nil // This will set the phase to .normalOperation.
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
        let ttl = provisionerNode.defaultTTL ?? LowerTransportLayer.defaultTtl
        
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
            // The message will be retransmit twice (with the same sequence number).
            try? self.networkManager.networkLayer.send(lowerTransportPdu: message, ofType: .networkPdu, withTtl: ttl, multipleTimes: true)
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
        try? networkManager.networkLayer.send(lowerTransportPdu: ack, ofType: .networkPdu, withTtl: ttl)
    }
    
    /// Sends all non-`nil` segments from `outgoingSegments` map from the given
    /// `sequenceZero` key.
    ///
    /// - parameter sequenceZero: The key to get segments from the map.
    func sendSegments(for sequenceZero: UInt16) {
        guard let count = outgoingSegments[sequenceZero]?.count, count > 0,
              let provisionerNode = meshNetwork.localProvisioner?.node else {
            return
        }
        /// The default TTL of the local Node.
        let ttl = provisionerNode.defaultTTL ?? LowerTransportLayer.defaultTtl
        /// Segment Acknowledgment Message is expected when the message is targetting
        /// a Unicast Address.
        var ackExpected: Bool = false
        
        for i in 0..<count {
            if let segment = self.outgoingSegments[sequenceZero]![i] {
                do {
                    try self.networkManager.networkLayer.send(lowerTransportPdu: segment, ofType: .networkPdu,
                                                              withTtl: ttl, multipleTimes: !ackExpected)
                    ackExpected = segment.destination.isUnicast
                } catch {
                    // Sending failed, remove the Segment from waiting list.
                    self.outgoingSegments[sequenceZero]![i] = nil
                }
            }
        }
        
        segmentTransmissionTimers.removeValue(forKey: sequenceZero)?.invalidate()
        if ackExpected && outgoingSegments[sequenceZero]!.hasMore {
            segmentTransmissionTimers[sequenceZero] =
                Timer.scheduledTimer(withTimeInterval: 0.200 + Double(ttl) * 0.050, repeats: false) { _ in
                    self.sendSegments(for: sequenceZero)
            }
        } else {
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
        return contains {  $0 != nil }
    }
    
}
