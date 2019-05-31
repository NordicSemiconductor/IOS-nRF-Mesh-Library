//
//  SegmentAcknowledmentMessage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 31/05/2019.
//

import Foundation

internal struct SegmentAcknowledmentMessage: ControlMessage {
    let opCode: UInt8
    let parameters: Data
    
    /// Flag set to `true` if the message was sent by a Friend
    /// on behalf of a Low Power node.
    let isOnBehalfOfLowPowerNode: Bool
    /// 13 least significant bits of SeqAuth.
    let segmentZero: UInt16
    /// Block acknowledgment for segments, bit field.
    let blockAck: UInt32
    
    init(_ networkPdu: NetworkPdu) {
        let data = networkPdu.transportPdu
        opCode = data[0] & 0x7F
        parameters = data.dropFirst()
        
        isOnBehalfOfLowPowerNode = (data[1] & 0x80) != 0
        segmentZero = (UInt16(data[1] & 0x7F) << 6) | UInt16(data[2] >> 2)
        blockAck = CFSwapInt32BigToHost(data.convert(offset: 3))
    }
    
    /// Returns whether the segment with given index has been received.
    ///
    /// - parameter m: The segment number.
    /// - returns: `True`, if the segment of the given number has been
    ///            acknowledged, `false` otherwise.
    func isSegmentReceived(_ m: UInt8) -> Bool {
        return blockAck & (1 << m) != 0
    }
    
    /// Returns whether all segments have been received.
    ///
    /// - parameter number: The total number of segments expected.
    /// - returns: `True` if all segments were received, `false` otherwise.
    func areAllSegmentsReceived(of number: UInt8) -> Bool {
        return areAllSegmentsReceived(lastSegmentNumber: number - 1)
    }
    
    /// Returns whether all segments have been received.
    ///
    /// - parameter lastSegmentNumber: The number of the last expected
    ///             segments (segN).
    /// - returns: `True` if all segments were received, `false` otherwise.
    func areAllSegmentsReceived(lastSegmentNumber: UInt8) -> Bool {
        return blockAck == (1 << (lastSegmentNumber + 1)) - 1
    }
}
