//
//  SegmentedControlMessage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 31/05/2019.
//

import Foundation

internal struct SegmentedControlMessage: SegmentedMessage {
    let opCode: UInt8
    
    let segmentZero: UInt16
    let segmentOffset: UInt8
    let lastSegmentNumber: UInt8
    let segment: Data
    
    var transportPdu: Data {
        let octet0: UInt8 = 0x80 | (opCode & 0x7F) // SEG = 1
        let octet1 = UInt8(segmentZero >> 5)
        let octet2 = UInt8((segmentZero & 0x3F) << 2) | (segmentOffset >> 3)
        let octet3 = ((segmentOffset & 0x07) << 5) | (lastSegmentNumber & 0x1F)
        return Data([octet0, octet1, octet2, octet3]) + segment
    }
    
    let type: LowerTransportPduType = .controlMessage
    
    init?(fromSegment networkPdu: NetworkPdu) {
        let data = networkPdu.transportPdu
        guard data.count >= 5, data[0] & 0x80 != 0 else {
            return nil
        }
        opCode = data[0] & 0x7F
        guard opCode != 0x00 else {
            return nil
        }
        segmentZero = (UInt16(data[1] & 0x7F) << 6) | UInt16(data[2] >> 2)
        segmentOffset = ((data[2] & 0x03) << 3) | ((data[3] & 0xE0) >> 5)
        lastSegmentNumber = data[3] & 0x1F
        guard segmentOffset <= lastSegmentNumber else {
            return nil
        }
        segment = data.dropFirst(4)
    }
}
