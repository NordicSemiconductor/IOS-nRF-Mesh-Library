//
//  SegmentAcknowledmentMessage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 31/05/2019.
//

import Foundation

internal struct SegmentAcknowledmentMessage: LowerTransportPdu {
    let source: Address?
    let destination: Address
    
    /// Message Op Code.
    let opCode: UInt8
    
    /// Flag set to `true` if the message was sent by a Friend
    /// on behalf of a Low Power node.
    let isOnBehalfOfLowPowerNode: Bool
    /// 13 least significant bits of SeqAuth.
    let segmentZero: UInt16
    /// Block acknowledgment for segments, bit field.
    let blockAck: UInt32
    /// This PDU contains the `blockAck` as `Data`.
    let upperTransportPdu: Data
    
    var transportPdu: Data {
        let octet0: UInt8 = opCode & 0x7F
        let octet1 = (isOnBehalfOfLowPowerNode ? 0x80 : 0x00) | UInt8(segmentZero >> 5)
        let octet2 = UInt8((segmentZero & 0x3F) << 2)
        return Data([octet0, octet1, octet2]) + upperTransportPdu
    }
    
    let type: LowerTransportPduType = .controlMessage
    
    /// Creates the Segmented Acknowledgement Message from the given Network PDU.
    /// If the PDU is not valid, it will return `nil`.
    ///
    /// - parameter networkPdu: The Network PDU received.
    init?(fromNetworkPdu networkPdu: NetworkPdu) {
        let data = networkPdu.transportPdu
        guard data.count == 7, data[0] & 0x80 == 0 else {
            return nil
        }
        opCode = data[0] & 0x7F
        guard opCode == 0x00 else {
            return nil
        }
        isOnBehalfOfLowPowerNode = (data[1] & 0x80) != 0
        segmentZero = (UInt16(data[1] & 0x7F) << 6) | UInt16(data[2] >> 2)
        blockAck = CFSwapInt32BigToHost(data.convert(offset: 3))
        upperTransportPdu = Data() + blockAck.bigEndian
        
        source = networkPdu.source
        destination = networkPdu.destination
    }
    
    /// Creates the ACK for given array of segments. At least one of
    /// segments must not be `nil`.
    ///
    /// - parameter segments: The list of segments to be acknowledged.
    init(for segments: [SegmentedMessage?]) {
        opCode = 0x00
        isOnBehalfOfLowPowerNode = false // Friendship is not supported.
        let segment = segments.first { $0 != nil }!!
        segmentZero = segment.segmentZero
        
        var ack: UInt32 = 0
        segments.forEach {
            if let segment = $0 {
                ack |= 1 << segment.segmentOffset
            }
        }
        blockAck = ack
        upperTransportPdu = Data() + blockAck.bigEndian
        
        // Assuming all segments have the same destination addresses.
        source = nil
        destination = segment.source!
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
