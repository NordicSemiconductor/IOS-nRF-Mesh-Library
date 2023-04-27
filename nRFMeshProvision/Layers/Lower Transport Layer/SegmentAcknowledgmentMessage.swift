/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

internal struct SegmentAcknowledgmentMessage: LowerTransportPdu {
    let source: Address
    let destination: Address
    let networkKey: NetworkKey
    let ivIndex: UInt32
    
    /// Message Op Code.
    let opCode: UInt8
    
    /// Flag set to `true` if the message was sent by a Friend
    /// on behalf of a Low Power node.
    let isOnBehalfOfLowPowerNode: Bool
    /// 13 least significant bits of SeqAuth.
    let sequenceZero: UInt16
    /// Block acknowledgment for segments, bit field.
    let blockAck: UInt32
    /// This PDU contains the `blockAck` as `Data`.
    let upperTransportPdu: Data
    
    var transportPdu: Data {
        let octet0: UInt8 = opCode & 0x7F
        let octet1 = (isOnBehalfOfLowPowerNode ? 0x80 : 0x00) | UInt8(sequenceZero >> 6)
        let octet2 = UInt8((sequenceZero & 0x3F) << 2)
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
        sequenceZero = (UInt16(data[1] & 0x7F) << 6) | UInt16(data[2] >> 2)
        blockAck = data.readBigEndian(fromOffset: 3)
        upperTransportPdu = Data() + blockAck.bigEndian
        
        source = networkPdu.source
        destination = networkPdu.destination
        networkKey = networkPdu.networkKey
        ivIndex = networkPdu.ivIndex
    }
    
    /// Creates the ACK for given array of segments. At least one of
    /// segments must not be `nil`.
    ///
    /// - parameter segments: The list of segments to be acknowledged.
    init(for segments: [SegmentedMessage?]) {
        opCode = 0x00
        isOnBehalfOfLowPowerNode = false // Friendship is not supported.
        let segment = segments.first { $0 != nil }!!
        sequenceZero = segment.sequenceZero
        
        var ack: UInt32 = 0
        segments.forEach {
            if let segment = $0 {
                ack |= 1 << segment.segmentOffset
            }
        }
        blockAck = ack
        upperTransportPdu = Data() + blockAck.bigEndian
        
        // Assuming all segments have the same source and destination addresses and network key.
        // Swapping source with destination. Destination here is guaranteed to be a Unicast Address.
        source = segment.destination
        destination = segment.source
        networkKey = segment.networkKey
        ivIndex = segment.ivIndex
    }
    
    /// Returns whether the segment with given index has been received.
    ///
    /// - parameter m: The segment number.
    /// - returns: `True`, if the segment of the given number has been
    ///            acknowledged, `false` otherwise.
    func isSegmentReceived(_ m: Int) -> Bool {
        return blockAck & (1 << m) != 0
    }
    
    /// Returns whether all segments have been received.
    ///
    /// - parameter segments: The array of segments received and expected.
    /// - returns: `True` if all segments were received, `false` otherwise.
    func areAllSegmentsReceived(of segments: [SegmentedMessage?]) -> Bool {
        return areAllSegmentsReceived(lastSegmentNumber: UInt8(segments.count - 1))
    }
    
    /// Returns whether all segments have been received.
    ///
    /// - parameter lastSegmentNumber: The number of the last expected
    ///             segments (segN).
    /// - returns: `True` if all segments were received, `false` otherwise.
    func areAllSegmentsReceived(lastSegmentNumber: UInt8) -> Bool {
        return blockAck == (1 << (lastSegmentNumber + 1)) - 1
    }
    
    /// Whether the source Node is busy and the message should be cancelled, or not.
    var isBusy: Bool {
        return blockAck == 0
    }
}

extension SegmentAcknowledgmentMessage: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "ACK (seqZero: \(sequenceZero), blockAck: 0x\(blockAck.hex))" 
    }
    
}
