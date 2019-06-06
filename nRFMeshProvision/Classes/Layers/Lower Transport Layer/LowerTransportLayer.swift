//
//  LowerTransportLayer.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 28/05/2019.
//

import Foundation

internal class LowerTransportLayer {
    /// The Default TTL will be used for sending messages, if the value has not been
    /// set in the Provisioner's Node. It is set to 127, which is the maximim TTL value.
    let defaultTtl: UInt8 = 127
    
    let networkManager: NetworkManager
    let meshNetwork: MeshNetwork
    let defaults: UserDefaults
    
    /// The map of incomplete segments.
    var segments: [UInt32 : [SegmentedMessage?]]
    
    init(_ networkManager: NetworkManager) {
        self.networkManager = networkManager
        self.meshNetwork = networkManager.meshNetwork!
        self.defaults = UserDefaults(suiteName: meshNetwork.uuid.uuidString)!
        self.segments = [:]
    }
    
    func handle(networkPdu: NetworkPdu) {
        guard networkPdu.transportPdu.count > 1 else {
            // Just to be sure. This for sure will be true.
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
        
        // The Lower Transport Layer behaves differently based on the message type.
        switch networkPdu.type {
        case .accessMessage:
            // Access Messages can be Unsegmented or Segmented.
            // This information is stored in the MSB bit of the first octet.
            let unsegmented = networkPdu.transportPdu[0] & 0x80 == 0
            if unsegmented {
                if let accessMessage = AccessMessage(fromUnsegmentedPdu: networkPdu) {
                    // Unsegmented message is not acknowledged. Just pass it to higher layer.
                    networkManager.upperTransportLayer.handleLowerTransportPdu(accessMessage)
                }
            } else {
                if let segment = SegmentedAccessMessage(fromSegmentPdu: networkPdu) {
                    // A segmented message may be composed of 1 or more segments.
                    if segment.isSingleSegment {
                        // A single segment message may immediately be acknowledged
                        if let provisionerNode = meshNetwork.localProvisioner?.node,
                            networkPdu.destination == provisionerNode.unicastAddress {
                            let ttl = provisionerNode.defaultTTL ?? defaultTtl
                            sendAck(for: [segment], usingNetworkKey: networkPdu.networkKey, withTtl: ttl)
                        }
                        let accessMessage = AccessMessage(fromSegments: [segment])
                        networkManager.upperTransportLayer.handleLowerTransportPdu(accessMessage)
                    } else {
                        // If a message is composed of multiple segments, they all need to
                        // be received before it can be processed.
                        let key = (UInt32(segment.source!) << 16) | UInt32(segment.segmentZero)
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
                            if let provisionerNode = meshNetwork.localProvisioner?.node,
                                networkPdu.destination == provisionerNode.unicastAddress {
                                let ttl = provisionerNode.defaultTTL ?? defaultTtl
                                sendAck(for: allSegments, usingNetworkKey: networkPdu.networkKey, withTtl: ttl)
                            }
                            let accessMessage = AccessMessage(fromSegments: allSegments)
                            networkManager.upperTransportLayer.handleLowerTransportPdu(accessMessage)
                        } else {
                            
                        }
                    }
                }
            }
        case .controlMessage:
            break
        }
    }
    
    func handle(unprovisionedDeviceBeacon: UnprovisionedDeviceBeacon) {
        print(unprovisionedDeviceBeacon)
    }
    
    func handle(secureNetworkBeacon: SecureNetworkBeacon) {
        print(secureNetworkBeacon)
        // TODO: handle Secure Beacon, change IV Index, etc.
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
