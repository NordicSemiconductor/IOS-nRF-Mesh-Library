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

internal struct SegmentedAccessMessage: SegmentedMessage {
    let message: MeshMessage?
    let userInitiated: Bool
    let source: Address
    let destination: Address
    let networkKey: NetworkKey
    let ivIndex: UInt32
    
    /// The Application Key identifier.
    /// This field is set to `nil` if the message is signed with a
    /// Device Key instead.
    let aid: UInt8?
    /// The size of Transport MIC: 4 or 8 bytes.
    let transportMicSize: UInt8
    /// The sequence number used to encode this message.
    let sequence: UInt32
    
    let sequenceZero: UInt16
    let segmentOffset: UInt8
    let lastSegmentNumber: UInt8
    
    let upperTransportPdu: Data
    
    var transportPdu: Data {
        var octet0: UInt8 = 0x80 // SEG = 1
        if let aid = aid {
            octet0 |= 0b01000000 // AKF = 1
            octet0 |= aid
        }
        let octet1 = ((transportMicSize << 4) & 0x80) | UInt8(sequenceZero >> 6)
        let octet2 = UInt8((sequenceZero & 0x3F) << 2) | (segmentOffset >> 3)
        let octet3 = ((segmentOffset & 0x07) << 5) | (lastSegmentNumber & 0x1F)
        return Data([octet0, octet1, octet2, octet3]) + upperTransportPdu
    }
    
    let type: LowerTransportPduType = .accessMessage
    
    /// Creates a Segment of an Access Message from a Network PDU that contains
    /// a segmented access message. If the PDU is invalid, the
    /// init returns `nil`.
    ///
    /// - parameter networkPdu: The received Network PDU with segmented
    ///                         Upper Transport message.
    init?(fromSegmentPdu networkPdu: NetworkPdu) {
        let data = networkPdu.transportPdu
        guard data.count >= 5, data[0] & 0x80 != 0 else {
            return nil
        }
        let akf = (data[0] & 0b01000000) != 0
        if akf {
            aid = data[0] & 0x3F
        } else {
            aid = nil
        }
        let szmic = data[1] >> 7
        transportMicSize = szmic == 0 ? 4 : 8
        
        sequenceZero = (UInt16(data[1] & 0x7F) << 6) | UInt16(data[2] >> 2)
        segmentOffset = ((data[2] & 0x03) << 3) | ((data[3] & 0xE0) >> 5)
        lastSegmentNumber = data[3] & 0x1F
        guard segmentOffset <= lastSegmentNumber else {
            return nil
        }
        upperTransportPdu = data.advanced(by: 4)
        sequence = (networkPdu.sequence & 0xFFE000) | UInt32(sequenceZero)
        
        source = networkPdu.source
        destination = networkPdu.destination
        networkKey = networkPdu.networkKey
        ivIndex = networkPdu.ivIndex
        message = nil
        userInitiated = false
    }

    /// Creates a Segment of an Access Message object from the Upper Transport PDU
    /// with given segment offset.
    ///
    /// - parameter pdu: The segmented Upper Transport PDU.
    /// - parameter networkKey: The Network Key to encrypt the PCU with.
    /// - parameter offset: The segment offset.
    init(fromUpperTransportPdu pdu: UpperTransportPdu, usingNetworkKey networkKey: NetworkKey, offset: UInt8) {
        self.message = pdu.message
        self.aid = pdu.aid
        self.source = pdu.source
        self.destination = pdu.destination.address
        self.networkKey = networkKey
        self.ivIndex = pdu.ivIndex
        self.transportMicSize = pdu.transportMicSize
        self.sequence = pdu.sequence
        self.sequenceZero = UInt16(pdu.sequence & 0x1FFF)
        self.segmentOffset = offset
        
        let lowerBound = Int(offset) * 12
        let upperBound = min(pdu.transportPdu.count, Int(offset + 1) * 12)
        let segment = pdu.transportPdu.subdata(in: lowerBound..<upperBound)
        self.lastSegmentNumber = UInt8((pdu.transportPdu.count + 11) / 12) - 1
        self.upperTransportPdu = segment
        self.userInitiated = pdu.userInitiated
    }
}

extension SegmentedAccessMessage: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "Segmented \(type) (akf: \(aid != nil ? "1, aid: 0x\(aid!.hex)" : "0"), szmic: \(transportMicSize == 4 ? 0 : 1), seqZero: \(sequenceZero), segO: \(segmentOffset), segN: \(lastSegmentNumber), data: 0x\(upperTransportPdu.hex))"
    }
    
}
