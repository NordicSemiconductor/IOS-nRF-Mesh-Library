//
//  NetworkPdu.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 27/05/2019.
//

import Foundation

internal struct NetworkPdu {
    /// Raw PDU data.
    let pdu: Data
    /// The Network Key used to decode/encode the PDU.
    let networkKey: NetworkKey
    
    /// Least significant bit of IV Index.
    let ivi: UInt8
    /// Value derived from the NetKey used to identify the Encryption Key
    /// and Privacy Key used to secure this PDU.
    let nid: UInt8
    /// PDU type.
    let type: LowerTransportPduType
    /// Time To Live.
    let ttl: UInt8
    /// Sequence Number.
    let sequence: UInt32
    /// Source Address.
    let source: Address
    /// Destination Address.
    let destination: Address
    /// Transport Protocol Data Unit. It is guaranteed to have 1 to 16 bytes.
    let transportPdu: Data
    
    /// Creates Network PDU object from received PDU. The initiator tries
    /// to deobfuscate and decrypt the data using given Network Key and IV Index.
    ///
    /// - parameter pdu:        The data received from mesh network.
    /// - parameter networkKey: The Network Key to decrypt the PDU.
    /// - returns: The deobfuscated and decided Network PDU object, or `nil`,
    ///            if the key or IV Index don't match.
    init?(decode pdu: Data, usingNetworkKey networkKey: NetworkKey) {
        self.pdu = pdu
        
        // Valid message must have at least 14 octets.
        guard pdu.count >= 14 else {
            return nil
        }
        
        // The first byte is not obfuscated.
        self.ivi  = pdu[0] >> 7
        self.nid  = pdu[0] & 0x7F
        
        // The NID must match.
        // If the Key Refresh procedure is in place, the received packet might have been
        // encrypted using an old key. We have to try both.
        var keySets: [NetworkKeyDerivaties] = []
        if nid == networkKey.nid {
            keySets.append(networkKey.keys)
        }
        if let oldNid = networkKey.oldNid, nid == oldNid {
            keySets.append(networkKey.oldKeys!)
        }
        guard !keySets.isEmpty else {
            return nil
        }
        
        // IVI should match the LSB bit of current IV Index.
        // If it doesn't, and the IV Update procedure is active, the PDU will be
        // deobfuscated and decoded with IV Index decremented by 1.
        var index = networkKey.ivIndex.index
        if ivi != index & 0x1 && networkKey.ivIndex.updateActive {
            index -= 1
        }
        
        let helper = OpenSSLHelper()
        for keys in keySets {
            // Deobfuscate CTL, TTL, SEQ and SRC.
            let deobfuscatedData = helper.deobfuscate(pdu, ivIndex: index, privacyKey: keys.privacyKey)!
            
            // First validation: Control Messages have NetMIC of size 64 bits.
            let ctl = deobfuscatedData[0] >> 7
            guard ctl == 0 || pdu.count >= 18 else {
                continue
            }
            
            let type = LowerTransportPduType(rawValue: ctl)!
            let ttl  = deobfuscatedData[0] & 0x7F
            // Multiple octet values use Big Endian.
            let sequence = UInt32(deobfuscatedData[1]) << 16 | UInt32(deobfuscatedData[2]) << 8 | UInt32(deobfuscatedData[3])
            let source   = Address(deobfuscatedData[4]) << 8 | Address(deobfuscatedData[5])
            
            let micOffset = pdu.count - Int(type.netMicSize)
            let destAndTransportPdu = pdu.subdata(in: 7..<micOffset)
            let mic = pdu.subdata(in: micOffset..<pdu.count)
            
            let networkNonce = Data([0x00]) + deobfuscatedData + Data([0x00, 0x00]) + index.bigEndian
            guard let decryptedData = helper.calculateDecryptedCCM(destAndTransportPdu,
                                                                   withKey: keys.encryptionKey,
                                                                   nonce: networkNonce, andMIC: mic) else {
                                                                    continue
            }
            
            self.networkKey = networkKey
            self.type = type
            self.ttl = ttl
            self.sequence = sequence
            self.source = source
            self.destination = Address(decryptedData[0]) << 8 | Address(decryptedData[1])
            self.transportPdu = decryptedData.subdata(in: 2..<decryptedData.count)
            return
        }
        return nil
    }
    
    /// Creates the Network PDU. This method enctypts and obfuscates data
    /// that are to be send to the mesh network.
    ///
    /// - parameter lowerTransportPdu: The data received from higher layer.
    /// - parameter sequence: The SEQ number of the PDU. Each PDU between the source
    ///                       and destination must have strictly increasing sequence number.
    /// - parameter ttl: Time To Leave.
    /// - returns: The Network PDU object.
    init(encode lowerTransportPdu: LowerTransportPdu,
         withSequence sequence: UInt32, andTtl ttl: UInt8) {
        let index = lowerTransportPdu.networkKey.ivIndex.index
        
        self.networkKey = lowerTransportPdu.networkKey
        self.ivi = UInt8(index & 0x1)
        self.nid = networkKey.nid
        self.type = lowerTransportPdu.type
        self.source = lowerTransportPdu.source
        self.destination = lowerTransportPdu.destination
        self.transportPdu = lowerTransportPdu.transportPdu
        self.ttl = ttl
        self.sequence = sequence
        
        let iviNid = (ivi << 7) | (nid & 0x7F)
        let ctlTtl = (type.rawValue << 7) | (ttl & 0x7F)
        
        // Data to be obfuscated: CTL/TTL, Sequence Number, Source Address.
        let seq = (Data() + sequence.bigEndian).dropFirst()
        let deobfuscatedData = Data() + ctlTtl + seq + source.bigEndian
        
        // Data to be encrypted: Destination Address, Transport PDU.
        let decryptedData = Data() + destination.bigEndian + transportPdu
        
        // The key set used for encryption depends on the Key Refresh Phase.
        let keys = networkKey.transmitKeys
        
        let helper = OpenSSLHelper()
        let networkNonce = Data([0x00]) + deobfuscatedData + Data([0x00, 0x00]) + index.bigEndian
        let encryptedData = helper.calculateCCM(decryptedData, withKey: keys.encryptionKey, nonce: networkNonce, andMICSize: type.netMicSize)!
        let obfuscatedData = helper.obfuscate(deobfuscatedData, usingPrivacyRandom: encryptedData, ivIndex: index, andPrivacyKey: keys.privacyKey)!
        
        self.pdu = Data() + iviNid + obfuscatedData + encryptedData
    }
    
    /// This method goes over all Network Keys in the mesh network and tries
    /// to deobfuscate and decode the network PDU.
    ///
    /// - parameter pdu:         The received PDU.
    /// - parameter meshNetwork: The mesh network for which the PDU should be decoded.
    /// - returns: The deobfuscated and decoded Network PDU, or `nil` if the PDU was not
    ///            signed with any of the Network Keys, the IV Index was not valid, or the
    ///            PDU was invalid.
    static func decode(_ pdu: Data, for meshNetwork: MeshNetwork) -> NetworkPdu? {
        for networkKey in meshNetwork.networkKeys {
            if let networkPdu = NetworkPdu(decode: pdu, usingNetworkKey: networkKey) {
                return networkPdu
            }
        }
        return nil
    }
}

private extension LowerTransportPduType {
    
    var netMicSize: UInt8 {
        switch self {
        case .accessMessage:  return 4 // 32 bits
        case .controlMessage: return 8 // 64 bits
        }
    }
    
}

extension NetworkPdu: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "Network PDU (\(source.hex)->\(destination.hex)): \(type), seq: \(sequence), ttl: \(ttl)"
    }
    
}
