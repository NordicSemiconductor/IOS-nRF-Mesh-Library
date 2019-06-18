//
//  Segment.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 31/05/2019.
//

import Foundation

internal protocol SegmentedMessage: LowerTransportPdu {
    /// 13 least significant bits of SeqAuth.
    var sequenceZero: UInt16 { get }
    /// This field is set to the segment number (zero-based)
    /// of the segment m of this Upper Transport PDU.
    var segmentOffset: UInt8 { get }
    /// This field is set to the last segment number (zero-based)
    /// of this Upper Transport PDU.
    var lastSegmentNumber: UInt8 { get }
}

internal extension SegmentedMessage {
    
    /// Returns whether the message is composed of only a single
    /// segment. Single segment messages are used to send short,
    /// acknowledged messages. The maximum size of payload of upper
    /// transport control PDU is 8 bytes.
    var isSingleSegment: Bool {
        return lastSegmentNumber == 0
    }
    
    /// Returns the `segmentOffset` as `Int`.
    var index: Int {
        return Int(segmentOffset)
    }
    
    /// Returns the expected number of segments for this message.
    var count: Int {
        return Int(lastSegmentNumber + 1)
    }
    
}
