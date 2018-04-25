//
//  NetworkLayer.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 20/02/2018.
//

import Foundation

public struct NetworkLayer {
    var stateManager        : MeshStateManager?
    var lowerTransport      : LowerTransportLayer!
    var netKey              : Data
    var sslHelper           : OpenSSLHelper
    var ivIndex             : Data!

    public init(withStateManager aStateManager: MeshStateManager,
                andSegmentAcknowlegdement aSegmentAckBlock: SegmentedMessageAcknowledgeBlock? = nil) {
        stateManager = aStateManager
        netKey = aStateManager.meshState.netKey
        ivIndex = aStateManager.meshState.IVIndex
        sslHelper = OpenSSLHelper()
        lowerTransport = LowerTransportLayer(withStateManager: aStateManager,
                                             andSegmentedAcknowlegdeMent: aSegmentAckBlock)
    }

    public mutating func incomingPDU(_ aPDU : Data) -> Any? {
        let k2Output = sslHelper.calculateK2(withN: netKey, andP: Data([0x00]))!
        let nid = k2Output[0] & 0x7F
        let calculactedIVINid = (ivIndex[2] & 0x01) | nid
        guard calculactedIVINid == aPDU.first else {
            print("Expected IV Index||NID did not match packet data, message is malfromed. NOOP")
            return nil
        }
        let encryptionKey = k2Output[1..<17]
        let privacyKey = k2Output[17..<33]
        let deobfuscatedPDU = sslHelper.deobfuscateENCPDU(aPDU, ivIndex: ivIndex, privacyKey: privacyKey)!
        let ctlttl = deobfuscatedPDU[0]
        let ctl = UInt8(ctlttl >> 7) == 0x01 ? true : false
        let ctlData = ctl ? Data([0x01]) : Data([0x00])
        let ttl = Data([ctlttl & 0x7F])
        let seq = deobfuscatedPDU[1..<4]
        let src = deobfuscatedPDU[4..<6]
        let micSize: Int = ctl ? 8 : 4
        
        //Decrypt network PDU
        let encryptedNetworkPDU = aPDU[8...(aPDU.count - micSize)] //7 first bytes are not a part of the ENCPDU
        let netMic = aPDU[(8 + encryptedNetworkPDU.count)..<(8 + encryptedNetworkPDU.count + micSize)]
        let nonceData = TransportNonce(networkNonceWithIVIndex: ivIndex, ctl: ctlData, ttl: ttl, seq: seq, src: src).data
        let decryptedNetworkPDU = sslHelper.calculateDecryptedCCM(encryptedNetworkPDU,
                                                                  withKey: encryptionKey,
                                                                  nonce: nonceData,
                                                                  dataSize: UInt8(encryptedNetworkPDU.count), andMIC: netMic)
        let dst = decryptedNetworkPDU![0...1]
        print("PDU: \(aPDU.hexString())")
        print("encPDU: \(encryptedNetworkPDU.hexString())")
        print("netMic: \(netMic.hexString())")
        print("Sequence: \(seq.hexString()), SRC: \(src.hexString()), ttl: \(ttl.hexString()), MICSize: \(micSize), encpduSz: \(encryptedNetworkPDU.count)")
        print("decrypted network PDU = \(decryptedNetworkPDU!.hexString())")
        return self.lowerTransport.append(withIncomingPDU: decryptedNetworkPDU!, ctl: ctlData, ttl: ttl, src: src, dst: dst, IVIndex: ivIndex, andSEQ: seq)
    }

    public init(withLowerTransportLayer aLowerTransport: LowerTransportLayer, andNetworkKey aNetKey: Data) {
        lowerTransport  = aLowerTransport
        netKey          = aNetKey
        sslHelper       = OpenSSLHelper()
    }

    //  P=Plaintext, OBF=Obfuscated, ENC=Encrypted with NetKey.
    //  P   P   OBF OBF OBF  OBF  ENC  ENC         ENC
    //  IVI NID CTL TTL SEQ  SRC  DST  TRANS_PDU   NETMIC
    //  [1] [7] [1] [7] [24] [16] [16] [1-16]      [32-64] (CTL:0 32, CTL:1 64)
    
    //Maxlen = 148 when CTL is set.
    //MAxLen = 120 when CTL is reset.
    public func createPDU() -> [Data] {
        let ivi = lowerTransport.params.ivIndex.last! & 0x01 //LSB of IVIndex
        let k2 = sslHelper.calculateK2(withN: netKey, andP: Data(bytes: [0x00]))
        let nid = k2![0]
        let iviNid = Data([ivi | nid])
        let encryptionKey = k2![1..<17]
        let privacyKey = k2![17..<33]
        var micSize: UInt8
        let ctlTtl = Data([(lowerTransport.params.ctl[0] << 7) | (lowerTransport.params.ttl[0] & 0x7F)])
        let lowerPDU = lowerTransport.createPDU()
        var sequence = lowerTransport.params.sequenceNumber

        var networkPDUs = [Data]()
        
        //Encrypt all PDUs
        for aPDU in lowerPDU {
            var nonce: TransportNonce
//            if lowerTransport.params.ctl == Data([0x01]) && lowerTransport.params.opcode == Data([0x00]) {
//            if lowerTransport.params.ctl == Data([0x00]) {
//                nonce = TransportNonce(proxyNonceWithIVIndex: lowerTransport.params.ivIndex, seq: sequence.sequenceData(), src: lowerTransport.params.sourceAddress)
//            } else {
                nonce = TransportNonce(networkNonceWithIVIndex: lowerTransport.params.ivIndex, ctl: lowerTransport.params.ctl, ttl: lowerTransport.params.ttl, seq: sequence.sequenceData(), src: lowerTransport.params.sourceAddress)
//            }
            var dataToEncrypt = Data(lowerTransport.params.destinationAddress)
            dataToEncrypt.append(aPDU)
            if lowerTransport.params.ctl == Data([0x01]) {
                micSize = 8
            } else {
                micSize = 4
            }

            if let encryptedData = sslHelper.calculateCCM(dataToEncrypt, withKey: encryptionKey, nonce: nonce.data, dataSize: UInt8(dataToEncrypt.count), andMICSize: micSize) {
                if let obfuscatedPDU = sslHelper.obfuscateENCPDU(encryptedData, cTLTTLValue: ctlTtl, sequenceNumber: sequence.sequenceData(), ivIndex: lowerTransport.params.ivIndex, privacyKey: privacyKey, andsrcAddr: lowerTransport.params.sourceAddress) {
                    var aNetworkPDU = Data()
                    aNetworkPDU.append(iviNid)
                    aNetworkPDU.append(obfuscatedPDU)
                    aNetworkPDU.append(encryptedData)
                    networkPDUs.append(aNetworkPDU)
                    //Increment sequence number
                    sequence.incrementSequneceNumber()
                }
            }
        }

        return networkPDUs
    }
}
