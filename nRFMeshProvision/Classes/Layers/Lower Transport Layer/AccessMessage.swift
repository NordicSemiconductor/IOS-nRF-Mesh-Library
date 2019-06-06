//
//  AccessMessage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 28/05/2019.
//

import Foundation

internal struct AccessMessage: LowerTransportPdu {
    let source: Address?
    let destination: Address
    
    /// Application Key identifier. This field is set to `nil`
    /// if the message is signed with a Device Key instead.
    let aid: UInt8?
    /// Upper Transport PDU.
    let upperTransportPdu: Data
    
    var transportPdu: Data {
        var octet0: UInt8 = 0x00 // SEG = 0
        if let aid = aid {
            octet0 |= 0b01000000 // AKF = 1
            octet0 |= aid
        }
        return Data([octet0]) + upperTransportPdu
    }
    
    let type: LowerTransportPduType = .accessMessage
    
    /// Creates an Access Message from a Network PDU that contains
    /// an unsegmented access message. If the PDU is invalid, the
    /// init returns `nil`.
    init?(fromUnsegmentedPdu networkPdu: NetworkPdu) {
        let data = networkPdu.transportPdu
        guard data.count >= 6 && data[0] & 0x80 == 0 else {
            return nil
        }
        let akf = (data[0] & 0b01000000) != 0
        if akf {
            aid = data[0] & 0x3F
        } else {
            aid = nil
        }
        upperTransportPdu = data.dropFirst()
        
        source = networkPdu.source
        destination = networkPdu.destination
    }
    
    /// Creates an Access Message object from the given list of segments.
    ///
    /// - parameter segments: List of ordered segments.
    init(fromSegments segments: [SegmentedAccessMessage]) {
        aid = segments.first!.aid
        
        // Segments are already sorted by `segmentOffset`.
        upperTransportPdu = segments
            .reduce(Data(), { (result, next) -> Data in
                return result + next.segment
            })
        
        // Assuming all segments have the same source and destination addresses.
        let segment = segments.first!
        source = segment.source
        destination = segment.destination
    }
}
