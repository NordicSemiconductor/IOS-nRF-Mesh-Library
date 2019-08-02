//
//  AccessMessage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 28/05/2019.
//

import Foundation

internal struct AccessMessage: LowerTransportPdu {
    let source: Address
    let destination: Address
    let networkKey: NetworkKey
    
    /// 6-bit Application Key identifier. This field is set to `nil`
    /// if the message is signed with a Device Key instead.
    let aid: UInt8?
    /// The sequence number used to encode this message.
    let sequence: UInt32
    /// The size of Transport MIC: 4 or 8 bytes.
    let transportMicSize: UInt8
    
    let upperTransportPdu: Data
    
    var transportPdu: Data {
        var octet0: UInt8 = 0x00 // SEG = 0
        if let aid = aid {
            octet0 |= 0b01000000 // AKF = 1
            octet0 |= aid
        }
        return Data([octet0]) + upperTransportPdu
    }
    
    let type: LowerTransportPduType = .accessMessage
    
    /// Creates an Access Message from a Network PDU that contains
    /// an unsegmented access message. If the PDU is invalid, the
    /// init returns `nil`.
    ///
    /// - parameter networkPdu: The received Network PDU with unsegmented
    ///                         Upper Transport message.
    init?(fromUnsegmentedPdu networkPdu: NetworkPdu) {
        let data = networkPdu.transportPdu
        guard data.count >= 6 && data[0] & 0x80 == 0 else {
            return nil
        }
        let akf = (data[0] & 0b01000000) != 0
        if akf {
            aid = data[0] & 0x3F
        } else {
            aid = nil
        }
        // For unsegmented messages, the size of the TransMIC is 32 bits.
        transportMicSize = 4
        sequence = networkPdu.sequence
        networkKey = networkPdu.networkKey
        upperTransportPdu = data.advanced(by: 1)
        
        source = networkPdu.source
        destination = networkPdu.destination
    }
    
    /// Creates an Access Message object from the given list of segments.
    ///
    /// - parameter segments: List of ordered segments.
    init(fromSegments segments: [SegmentedAccessMessage]) {
        // Assuming all segments have the same AID, source and destination addresses and TransMIC.
        let segment = segments.first!
        aid = segment.aid
        transportMicSize = segment.transportMicSize
        source = segment.source
        destination = segment.destination
        sequence = segment.sequence
        networkKey = segment.networkKey
        
        // Segments are already sorted by `segmentOffset`.
        upperTransportPdu = segments.reduce(Data()) {
            $0 + $1.upperTransportPdu
        }
    }
    
    /// Creates an Access Message object from the Upper Transport PDU.
    ///
    /// - parameter pdu: The Upper Transport PDU.
    /// - parameter networkKey: The Network Key to encrypt the PCU with.
    init(fromUnsegmentedUpperTransportPdu pdu: UpperTransportPdu, usingNetworkKey networkKey: NetworkKey) {
        self.aid = pdu.aid
        self.upperTransportPdu = pdu.transportPdu
        self.transportMicSize = 4
        self.source = pdu.source
        self.destination = pdu.destination
        self.sequence = pdu.sequence
        self.networkKey = networkKey
    }
}

extension AccessMessage: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "\(type) (\(source.hex)->\(destination.hex)): Seq: \(sequence), 0x\(upperTransportPdu.hex), MIC size: \(transportMicSize) bytes"
    }
    
}
