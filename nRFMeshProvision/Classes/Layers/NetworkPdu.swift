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
    
    init?(_ data: Data, using networkKey: NetworkKey, and ivIndex: IvIndex) {
        // Valid message must have at least 14 octets.
        guard data.count >= 14 else {
            return nil
        }
        
        // The first byte is not obfuscated.
        ivi  = data[0] >> 7
        nid  = data[0] & 0x7F
        
        // The NID must match.
        guard nid == networkKey.nid else {
            return nil
        }
        
        // Deobfuscate CTL, TTL, SEQ and SRC.
        let helper = OpenSSLHelper()
        let deobfuscatedData = helper.deobfuscateNetworkPdu(data, ivIndex: ivIndex.index, privacyKey: networkKey.privacyKey)!
        
        // First validation: Control Messages have NetMIC of size 64 bits.
        let ctl = deobfuscatedData[0] >> 7
        guard ctl == 0 || data.count >= 18 else {
            return nil
        }
        
        type = NetworkPduType(rawValue: ctl)!
        ttl  = deobfuscatedData[0] & 0x7F
        // Multiple octet values use Big Endian.
        sequence = UInt32(deobfuscatedData[1]) << 16 | UInt32(deobfuscatedData[2]) << 8 | UInt32(deobfuscatedData[3])
        source   = Address(deobfuscatedData[4]) << 8 | Address(deobfuscatedData[5])
        
        let micOffset = data.count - type.netMicSize
        let destAndTransportPdu = data.subdata(in: 7..<micOffset)
        let mic = data.subdata(in: micOffset..<data.count)
        
        let networkNonce = Data([0x00]) + deobfuscatedData + Data([0x00, 0x00]) + ivIndex.index.bigEndian
        guard let decryptedData = helper.calculateDecryptedCCM(destAndTransportPdu,
                                                               withKey: networkKey.encryptionKey,
                                                               nonce: networkNonce, andMIC: mic) else {
                                                                return nil
        }
        
        destination = Address(decryptedData[0]) << 8 | Address(decryptedData[1])
        transportPdu = decryptedData.subdata(in: 2..<decryptedData.count)
    }
}
