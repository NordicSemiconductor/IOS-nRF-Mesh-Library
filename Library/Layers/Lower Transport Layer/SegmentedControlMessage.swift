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

internal struct SegmentedControlMessage: SegmentedMessage {
    let message: MeshMessage?
    let localElement: Element?
    let userInitiated: Bool
    let source: Address
    let destination: Address
    let networkKey: NetworkKey
    let ivIndex: UInt32
    let ttl: UInt8
    
    /// Message Op Code.
    let opCode: UInt8
    
    let sequenceZero: UInt16
    let segmentOffset: UInt8
    let lastSegmentNumber: UInt8
    
    let upperTransportPdu: Data
    
    var transportPdu: Data {
        let octet0: UInt8 = 0x80 | (opCode & 0x7F) // SEG = 1
        let octet1 = UInt8(sequenceZero >> 5)
        let octet2 = UInt8((sequenceZero & 0x3F) << 2) | (segmentOffset >> 3)
        let octet3 = ((segmentOffset & 0x07) << 5) | (lastSegmentNumber & 0x1F)
        return Data([octet0, octet1, octet2, octet3]) + upperTransportPdu
    }
    
    let type: LowerTransportPduType = .controlMessage
    
    /// Creates a Segment of an Control Message from a Network PDU that contains
    /// a segmented control message. If the PDU is invalid, the
    /// init returns `nil`.
    ///
    /// - parameter networkPdu: The received Network PDU with segmented
    ///                         Upper Transport message.
    init?(fromSegment networkPdu: NetworkPdu) {
        let data = networkPdu.transportPdu
        guard data.count >= 5, data[0] & 0x80 != 0 else {
            return nil
        }
        opCode = data[0] & 0x7F
        guard opCode != 0x00 else {
            return nil
        }
        sequenceZero = (UInt16(data[1] & 0x7F) << 6) | UInt16(data[2] >> 2)
        segmentOffset = ((data[2] & 0x03) << 3) | ((data[3] & 0xE0) >> 5)
        lastSegmentNumber = data[3] & 0x1F
        guard segmentOffset <= lastSegmentNumber else {
            return nil
        }
        upperTransportPdu = data.advanced(by: 4)
        
        source = networkPdu.source
        destination = networkPdu.destination
        networkKey = networkPdu.networkKey
        ivIndex = networkPdu.ivIndex
        ttl = networkPdu.ttl
        message = nil
        localElement = nil
        userInitiated = false
    }
}

extension SegmentedControlMessage: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "Segmented \(type) (opCode: \(opCode), seqZero: \(sequenceZero), segO: \(segmentOffset), segN: \(lastSegmentNumber), data: 0x\(upperTransportPdu.hex))"
    }
    
}
