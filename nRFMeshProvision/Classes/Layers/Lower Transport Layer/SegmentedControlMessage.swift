//
//  SegmentedControlMessage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 31/05/2019.
//

import Foundation

internal struct SegmentedControlMessage: SegmentedMessage {
    let source: Address
    let destination: Address
    let networkKey: NetworkKey
    
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
    }
}

extension SegmentedControlMessage: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "Segmented \(type) (\(source.hex)->\(destination.hex)) for SeqZero: \(sequenceZero) (\(segmentOffset + 1)/\(lastSegmentNumber + 1)), Op Code: \(opCode), 0x\(upperTransportPdu.hex)"
    }
    
}
