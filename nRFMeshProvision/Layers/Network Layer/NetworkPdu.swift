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

internal struct NetworkPdu {
    /// Raw PDU data.
    let pdu: Data
    /// The Network Key used to decode/encode the PDU.
    let networkKey: NetworkKey
    /// The IV Index used to decode/encode the PDU.
    let ivIndex: UInt32
    
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
    /// - parameters:
    ///   - pdu:        The data received from mesh network.
    ///   - pduType:    The type of the PDU: ``PduType/networkPdu`` or ``PduType/proxyConfiguration``.
    ///   - networkKey: The Network Key to decrypt the PDU.
    ///   - ivIndex:    The current IV Index.
    /// - returns: The deobfuscated and decoded Network PDU object, or `nil`,
    ///            if the key or IV Index don't match.
    init?(decode pdu: Data, ofType pduType: PduType,
          usingNetworkKey networkKey: NetworkKey, andIvIndex ivIndex: IvIndex) {
        guard pduType == .networkPdu || pduType == .proxyConfiguration else {
            return nil
        }
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
        var keySets: [NetworkKeyDerivatives] = []
        if nid == networkKey.keys.nid {
            keySets.append(networkKey.keys)
        }
        if let oldNid = networkKey.oldKeys?.nid, nid == oldNid {
            keySets.append(networkKey.oldKeys!)
        }
        guard !keySets.isEmpty else {
            return nil
        }
        
        // IVI should match the LSB bit of current IV Index.
        // If it doesn't, the PDU will be deobfuscated and decoded with IV Index
        // decremented by 1.
        // See: Bluetooth Mesh Profile 1.0.1 Specification, chapter: 3.10.5.
        self.ivIndex = ivIndex.index(for: ivi)
        
        for keys in keySets {
            // Deobfuscate CTL, TTL, SEQ and SRC.
            let obfuscatedData = pdu.subdata(in: 1..<7) // 6 bytes following IVI
            let random = pdu.subdata(in: 7..<14)        // 7 bytes of encrypted data
            let deobfuscatedData = Crypto.obfuscate(obfuscatedData, usingPrivacyRandom: random,
                                                    ivIndex: self.ivIndex, andPrivacyKey: keys.privacyKey)
            
            // First validation: Control Messages have NetMIC of size 64 bits.
            let ctl = deobfuscatedData[0] >> 7
            guard ctl == 0 || pdu.count >= 18 else {
                continue
            }
            
            let type = LowerTransportPduType(rawValue: ctl)!
            let ttl  = deobfuscatedData[0] & 0x7F
            // Multiple octet values use Big Endian.
            let sequence = UInt32(deobfuscatedData[1]) << 16
                         | UInt32(deobfuscatedData[2]) << 8
                         | UInt32(deobfuscatedData[3])
            let source   = Address(deobfuscatedData[4]) << 8
                         | Address(deobfuscatedData[5])
            
            let micOffset = pdu.count - Int(type.netMicSize)
            let destAndTransportPdu = pdu.subdata(in: 7..<micOffset)
            let mic = pdu.subdata(in: micOffset..<pdu.count)
            
            var nonce = Data([pduType.nonceId])
                + deobfuscatedData
                + Data([0x00, 0x00])
                + self.ivIndex.bigEndian
            if case .proxyConfiguration = pduType {
                nonce[1] = 0x00 // Pad
            }
            guard let decryptedData = Crypto.decrypt(destAndTransportPdu,
                                                     withEncryptionKey: keys.encryptionKey,
                                                     nonce: nonce, andMIC: mic,
                                                     withAdditionalData: nil) else { continue }
            
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
    
    /// Creates the Network PDU. This method encrypts and obfuscates data
    /// that are to be send to the mesh network.
    ///
    /// - parameters:
    ///   - lowerTransportPdu: The data received from higher layer.
    ///   - pduType: The type of the PDU: ``PduType/networkPdu`` or ``PduType/proxyConfiguration``.
    ///   - sequence: The SEQ number of the PDU. Each PDU between the source
    ///                       and destination must have strictly increasing sequence number.
    ///   - ttl: Time To Live.
    /// - returns: The Network PDU object.
    init(encode lowerTransportPdu: LowerTransportPdu, ofType pduType: PduType,
         withSequence sequence: UInt32, andTtl ttl: UInt8) {
        guard pduType == .networkPdu || pduType == .proxyConfiguration else {
            fatalError("Only .networkPdu and .configurationPdu may be encoded into a NetworkPdu")
        }
        // The key set used for encryption depends on the Key Refresh Phase.
        let networkKey = lowerTransportPdu.networkKey
        let keys = networkKey.transmitKeys
        
        self.networkKey = networkKey
        self.ivIndex = lowerTransportPdu.ivIndex
        self.ivi = UInt8(ivIndex & 0x1)
        self.nid = keys.nid
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
        
        var nonce = Data([pduType.nonceId]) + deobfuscatedData + Data([0x00, 0x00]) + ivIndex.bigEndian
        if case .proxyConfiguration = pduType {
            nonce[1] = 0x00 // Pad
        }
        let encryptedData = Crypto.encrypt(decryptedData,
                                           withEncryptionKey: keys.encryptionKey,
                                           nonce: nonce,
                                           andMICSize: type.netMicSize,
                                           withAdditionalData: nil)
        let obfuscatedData = Crypto.obfuscate(deobfuscatedData,
                                              usingPrivacyRandom: encryptedData,
                                              ivIndex: ivIndex,
                                              andPrivacyKey: keys.privacyKey)
        
        self.pdu = Data() + iviNid + obfuscatedData + encryptedData
    }
}

private extension PduType {
    
    var nonceId: UInt8 {
        switch self {
        case .networkPdu:
            return 0x00
        case .proxyConfiguration:
            return 0x03
        default:
            fatalError("Unsupported PDU Type: \(self)")
        }
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

internal struct NetworkPduDecoder {
    private init() {}
    
    /// This method goes over all Network Keys in the mesh network and tries
    /// to deobfuscate and decode the network PDU.
    ///
    /// - parameters:
    ///   - pdu:         The received PDU.
    ///   - type:        The type of the PDU: ``PduType/networkPdu`` or ``PduType/proxyConfiguration``.
    ///   - meshNetwork: The mesh network for which the PDU should be decoded.
    /// - returns: The deobfuscated and decoded Network PDU, or `nil` if the PDU was not
    ///            signed with any of the Network Keys, the IV Index was not valid, or the
    ///            PDU was invalid.
    static func decode(_ pdu: Data, ofType type: PduType, for meshNetwork: MeshNetwork) -> NetworkPdu? {
        for networkKey in meshNetwork.networkKeys {
            if let networkPdu = NetworkPdu(decode: pdu, ofType: type,
                                           usingNetworkKey: networkKey, andIvIndex: meshNetwork.ivIndex) {
                return networkPdu
            }
        }
        return nil
    }
    
}

extension NetworkPdu: CustomDebugStringConvertible {
    
    var debugDescription: String {
        let micSize = Int(type.netMicSize)
        let encryptedDataSize = pdu.count - micSize - 9
        let encryptedData = pdu.subdata(in: 9..<9 + encryptedDataSize)
        let mic = pdu.advanced(by: 9 + encryptedDataSize)
        return "Network PDU (ivi: \(ivi), nid: 0x\(nid.hex), ctl: \(type.rawValue), ttl: \(ttl), seq: \(sequence), src: \(source.hex), dst: \(destination.hex), transportPdu: 0x\(encryptedData.hex), netMic: 0x\(mic.hex))"
    }
    
}
