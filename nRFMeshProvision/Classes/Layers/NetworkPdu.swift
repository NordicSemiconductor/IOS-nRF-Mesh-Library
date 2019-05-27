//
//  NetworkPdu.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 27/05/2019.
//

import Foundation

internal enum NetworkPduType: UInt8 {
    case accessMessage  = 0
    case controlMessage = 1
    
    var netMicSize: Int {
        switch self {
        case .accessMessage:  return 4 // 32 bits
        case .controlMessage: return 8 // 64 bits
        }
    }
}

internal struct NetworkPdu {
    /// Least significant bit of IV Index.
    let ivi: UInt8
    /// Value derived from the NetKey used to identify the Encryption Key
    /// and Privacy Key used to secure this PDU.
    let nid: UInt8
    /// PDU type.
    let type: NetworkPduType
    /// Time To Live.
    let ttl: UInt8
    /// Sequence Number.
    let sequence: UInt32
    /// Source Address.
    let source: Address
    /// Destination Address.
    let destination: Address
    /// Transport Protocol Data Unit.
    let transportPdu: Data
    /// Message Integrity Check for Network.
    let netMic: Data
    
    init?(_ data: Data) {
        // Valid message must have at least 14 octets.
        guard data.count >= 14 else {
            return nil
        }
        // Control Messages have NetMIC of size 64 bits.
        let ctl = data[1] >> 7
        guard ctl == 0 || data.count >= 18 else {
            return nil
        }
        
        ivi  = data[0] >> 7
        nid  = data[0] & 0x7F
        type = NetworkPduType(rawValue: ctl)!
        ttl  = data[1] & 0x7F
        // Multiple octet values use Big Endian.
        sequence    = UInt32(data[2] << 16) | UInt32(data[3] << 8) | UInt32(data[4])
        source      = Address(data[5] << 8) | Address(data[6])
        destination = Address(data[7] << 8) | Address(data[8])
        
        let micOffset = data.count - type.netMicSize
        transportPdu = data.subdata(in: 9..<micOffset)
        netMic = data.subdata(in: micOffset..<data.count)
    }
}
