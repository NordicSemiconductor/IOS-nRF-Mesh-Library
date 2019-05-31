//
//  LowerTransportPdu.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 28/05/2019.
//

import Foundation

internal struct LowerTransportPdu {
    /// The Application Key identifier.
    /// This field is set to `nil` if the message is signed with a
    /// Device Key instead.
    let aid: UInt8?
    /// Upper Transport PDU.
    let upperTransportPdu: Data
    
    init(fromUnsegmented networkPdu: NetworkPdu) {
        let data = networkPdu.transportPdu
        let akf = (data[0] & 0b01000000) != 0
        if akf {
            aid = data[0] & 0x3F
        } else {
            aid = nil
        }
        upperTransportPdu = data.dropFirst()
    }
    
    init(fromSegments segments: [SegmentedLowerTransportPdu]) {
        aid = segments.first!.aid
        
        upperTransportPdu = segments
            .sorted(by: { $0.segmentOffset < $1.segmentOffset })
            .reduce(Data(), { (result, next) -> Data in
                return result + next.segment
            })
    }
}
