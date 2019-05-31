//
//  SegmentedControlMessagePdu.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 31/05/2019.
//

import Foundation

internal struct SegmentedControlMessagePdu {
    /// Message Op Code.
    let opCode: UInt8
    /// 13 least significant bits of SeqAuth.
    let segmentZero: UInt16
    /// This field is set to the segment number (zero-based)
    /// of the segment m of this Upper Transport PDU.
    let segmentOffset: UInt8
    /// This field is set to the last segment number (zero-based)
    /// of this Upper Transport PDU.
    let lastSegmentNumber: UInt8
    /// Segment data.
    let segment: Data
    
    init(_ networkPdu: NetworkPdu) {
        let data = networkPdu.transportPdu
        opCode = data[0] & 0x7F
        segmentZero = (UInt16(data[1] & 0x7F) << 6) | UInt16(data[2] >> 2)
        segmentOffset = ((data[2] & 0x03) << 3) | ((data[3] & 0xE0) >> 5)
        lastSegmentNumber = data[3] & 0x1F
        segment = data.dropFirst(4)
    }
}
