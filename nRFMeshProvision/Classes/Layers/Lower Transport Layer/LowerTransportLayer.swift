//
//  LowerTransportLayer.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 28/05/2019.
//

import Foundation

internal class LowerTransportLayer {
    /// The Default TTL will be used for sending messages, if the value has not been
    /// set in the Provisioner's Node. It is set to 5, which is reasonable value.
    /// If this value is not enough, make sure the default TTL value is set for the
    /// Provisioner.
    let defaultTtl: UInt8 = 5
    /// The time after which an incomplete segmented message will be discarded, in seconds.
    let defaultIncompleteTimerInterval: TimeInterval = 10.0
    
    let networkManager: NetworkManager
    let meshNetwork: MeshNetwork
    /// The storage for keeping sequence numbers. Each mesh network (with different UUID)
    /// has a unique storage, which can be reloaded when the network is imported after it
    /// was used before.
    let defaults: UserDefaults
    
    /// The map of incomplete segments. The key consists of 16 bits of source address in
    /// 2 most significant bytes and `segmentZero` field in 13 least significant bits.
    /// See `UInt32(keyFor:segment)` below.
    var segments: [UInt32 : [SegmentedMessage?]]
    /// The map of active timers. The key consists of 16 bits of source address in
    /// 2 most significant bytes and `segmentZero` field in 13 least significant bits.
    /// See `UInt32(keyFor:segment)` below.
    var incompleteTimers: [UInt32 : Timer]
    /// The map of acknowledgment timers. The key consists of 16 bits of source address in
    /// 2 most significant bytes and `segmentZero` field in 13 least significant bits.
    /// See `UInt32(keyFor:segment)` below.
    var acknowledgmentTimers: [UInt32 : Timer]
    
    init(_ networkManager: NetworkManager) {
        self.networkManager = networkManager
        self.meshNetwork = networkManager.meshNetwork!
        self.defaults = UserDefaults(suiteName: meshNetwork.uuid.uuidString)!
        self.segments = [:]
        self.incompleteTimers = [:]
        self.acknowledgmentTimers = [:]
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
        // Check, if the sequence number is greater than the one used last
        // time by the source address.
        let lastSequence = defaults.integer(forKey: networkPdu.source.hex)
        let localSeqAuth = (UInt64(networkPdu.networkKey.ivIndex.index) << 24) | UInt64(lastSequence)
        let receivedSeqAuth = (UInt64(networkPdu.networkKey.ivIndex.index) << 24) | UInt64(networkPdu.sequence)
       
        guard receivedSeqAuth > localSeqAuth else {
            // Ignore that message.
            return
        }
        // SeqAuth is valid, save the new sequence authentication value.
        defaults.set(networkPdu.sequence, forKey: networkPdu.source.hex)
        
        // Lower Transport Messages can be Unsegmented or Segmented.
        let unsegmented = networkPdu.transportPdu[0] & 0x80 == 0
        
        // The Lower Transport Layer behaves differently based on the message type.
        switch networkPdu.type {
        case .accessMessage:
            // This information is stored in the MSB bit of the first octet.
            if unsegmented {
                if let accessMessage = AccessMessage(fromUnsegmentedPdu: networkPdu) {
                    // Unsegmented message is not acknowledged. Just pass it to higher layer.
                    networkManager.upperTransportLayer.handle(lowerTransportPdu: accessMessage)
                }
            } else {
                if let segment = SegmentedAccessMessage(fromSegmentPdu: networkPdu) {
                    // A segmented message may be composed of 1 or more segments.
                    if segment.isSingleSegment {
                        // A single segment message may immediately be acknowledged
                        if let provisionerNode = meshNetwork.localProvisioner?.node,
                            networkPdu.destination == provisionerNode.unicastAddress {
                            let ttl = networkPdu.ttl > 0 ? provisionerNode.defaultTTL ?? defaultTtl : 0
                            sendAck(for: [segment], usingNetworkKey: networkPdu.networkKey, withTtl: ttl)
                        }
                        let accessMessage = AccessMessage(fromSegments: [segment])
                        networkManager.upperTransportLayer.handle(lowerTransportPdu: accessMessage)
                    } else {
                        // If a message is composed of multiple segments, they all need to
                        // be received before it can be processed.
                        let key = UInt32(keyFor: networkPdu.source, segment: segment)
                        if segments[key] == nil {
                            segments[key] = Array<SegmentedMessage?>(repeating: nil, count: segment.count)
                        }
                        guard segments[key]!.count > segment.index && segments[key]![segment.index] == nil else {
                            // Segment was sent again or it's invalid. We can stop here.
                            return
                        }
                        segments[key]![segment.index] = segment
                        
                        // If all segments were received, send ACK and send the PDU to Upper
                        // Transport Layer for processing.
                        if segments[key]!.isComplete {
                            let allSegments = segments.removeValue(forKey: key)! as! [SegmentedAccessMessage]
                            // If the access message was targetting directly the local Provisioner...
                            if let provisionerNode = meshNetwork.localProvisioner?.node,
                                networkPdu.destination == provisionerNode.unicastAddress {
                                // ...send the ACK that all segments were received...
                                let ttl = networkPdu.ttl > 0 ? provisionerNode.defaultTTL ?? defaultTtl : 0
                                sendAck(for: allSegments, usingNetworkKey: networkPdu.networkKey, withTtl: ttl)
                                
                                // ...and invalidate timers.
                                incompleteTimers.removeValue(forKey: key)?.invalidate()
                                acknowledgmentTimers.removeValue(forKey: key)?.invalidate()
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
                            incompleteTimers[key] = Timer(timeInterval: defaultIncompleteTimerInterval, repeats: false) { _ in
                                self.incompleteTimers.removeValue(forKey: key)?.invalidate()
                                self.acknowledgmentTimers.removeValue(forKey: key)?.invalidate()
                                self.segments.removeValue(forKey: key)
                            }
                            // If the Lower Transport Layer receives any segment while the acknowlegment
                            // timer is inactive, it shall restart the timer. Active timer should not be restarted.
                            if acknowledgmentTimers[key] == nil {
                                let ttl = provisionerNode.defaultTTL ?? self.defaultTtl
                                acknowledgmentTimers[key] = Timer(timeInterval: 0.150 + Double(ttl) * 0.050, repeats: false) { _ in
                                    let ttl = networkPdu.ttl > 0 ? ttl : 0
                                    self.sendAck(for: self.segments[key]!, usingNetworkKey: networkPdu.networkKey, withTtl: ttl)
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
                if let ack = SegmentAcknowledmentMessage(fromNetworkPdu: networkPdu) {
                    
                }
            default:
                break
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
            networkKey.ivIndex.index = secureNetworkBeacon.ivIndex
            networkKey.ivIndex.updateActive = secureNetworkBeacon.ivUpdateActive
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
    
    /// This method tries to send the Lower Transport Message of given type to the
    /// given destination address. If the local Provisioner does not exist, or
    /// does not have Unicast Address assigned, this method does nothing.
    ///
    /// If the `transporter` throws an error during sending, this error will be ignored.
    ///
    /// - parameter pdu:         The Upper Transport PDU to be sent.
    /// - parameter type:        The PDU type.
    /// - parameter networkKey:  The Network Key to be used to encrypt the message on
    ///                          on Network Layer.
    func handle(outgoingPdu pdu: UpperTransportPdu, ofType type: PduType,
                usingNetworkKey networkKey: NetworkKey) {
        
    }
    
}

private extension UInt32 {
    
    /// Returns the key used in maps in Lower Transport Layer to keep
    /// segments received from given source address.
    init(keyFor source: Address, segment: SegmentedMessage) {
        self = (UInt32(source) << 16) | UInt32(segment.segmentZero)
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
    /// - parameter ttl:        Initial Time To Leave (TTL) value.
    func sendAck(for segments: [SegmentedMessage?], usingNetworkKey networkKey: NetworkKey, withTtl ttl: UInt8) {
        let ack = SegmentAcknowledmentMessage(for: segments)
        networkManager.networkLayer.handle(outgoingPdu: ack, ofType: .networkPdu,
                                           usingNetworkKey: networkKey, withTtl: ttl)
    }
    
}

private extension Array where Element == SegmentedMessage? {
    
    /// Returns whether all the segments were received.
    var isComplete: Bool {
        return !contains { $0 == nil }
    }
    
}
