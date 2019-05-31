//
//  AccessMessage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 28/05/2019.
//

import Foundation

internal struct AccessMessage: LowerTransportPdu {
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
    
    init?(fromUnsegmented networkPdu: NetworkPdu) {
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
    }
    
    init(fromSegments segments: [SegmentedAccessMessage]) {
        aid = segments.first!.aid
        
        upperTransportPdu = segments
            .sorted(by: { $0.segmentOffset < $1.segmentOffset })
            .reduce(Data(), { (result, next) -> Data in
                return result + next.segment
            })
    }
}
