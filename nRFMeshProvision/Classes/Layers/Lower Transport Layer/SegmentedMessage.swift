//
//  Segment.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 31/05/2019.
//

import Foundation

internal protocol SegmentedMessage: LowerTransportPdu {
    /// 13 least significant bits of SeqAuth.
    var segmentZero: UInt16 { get }
    /// This field is set to the segment number (zero-based)
    /// of the segment m of this Upper Transport PDU.
    var segmentOffset: UInt8 { get }
    /// This field is set to the last segment number (zero-based)
    /// of this Upper Transport PDU.
    var lastSegmentNumber: UInt8 { get }
    /// Segment data.
    var segment: Data { get }
}
