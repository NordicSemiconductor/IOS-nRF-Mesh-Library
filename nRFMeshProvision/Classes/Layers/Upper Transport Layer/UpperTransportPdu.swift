//
//  UpperTransportPdu.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 28/05/2019.
//

import Foundation

internal struct UpperTransportPdu {
    /// Source Address. This is set to `nil` for outgoing messages,
    /// where the Network Layer will set the local Provisioner's
    /// Unicast Address as source address.
    let source: Address
    /// Destination Address.
    let destination: Address
    /// 6-bit Application Key identifier. This field is set to `nil`
    /// if the message is signed with a Device Key instead.
    let aid: UInt8?
    /// The sequence number used to encode this message.
    let sequence: UInt32
    /// The size of Transport MIC: 4 or 8 bytes.
    let transportMicSize: UInt8
    /// The Access Layer data.
    let accessPdu: Data
    /// The raw data of Upper Transport Layer PDU.
    let transportPdu: Data
    
    init?(fromLowerTransportAccessMessage accessMessage: AccessMessage, usingKey key: Data) {
        let micSize = Int(accessMessage.transportMicSize)
        let pduSize = accessMessage.upperTransportPdu.count
        let mic = accessMessage.upperTransportPdu.subdata(in: pduSize - micSize..<pduSize)
        
        // The nonce type is 0x01 for messages signed with Application Key and
        // 0x02 for messages signed using Device Key (Configuration Messages).
        let type: UInt8 = accessMessage.aid != 0 ? 0x01 : 0x02
        // ASZMIC is set to 1 for messages sent with high security
        // (64-bit TransMIC). This is possible only for Segmented Access Messages.
        let aszmic: UInt8 = micSize == 4 ? 0 : 1
        let seq = (Data() + accessMessage.sequence.bigEndian).dropFirst()
        
        let nonce = Data([type, aszmic << 7]) + seq
            + accessMessage.source.bigEndian
            + accessMessage.destination.bigEndian
            + accessMessage.networkKey.ivIndex.index.bigEndian
        
        guard let decryptedData = OpenSSLHelper().calculateDecryptedCCM(accessMessage.upperTransportPdu,
                  withKey: key, nonce: nonce, andMIC: mic) else {
             return nil
        }
        source = accessMessage.source
        destination = accessMessage.destination
        aid = accessMessage.aid
        transportMicSize = accessMessage.transportMicSize
        transportPdu = accessMessage.upperTransportPdu
        accessPdu = decryptedData
        sequence = accessMessage.sequence
    }
    
    init(fromMeshMessage message: MeshMessage, sentFrom source: Address, to destination: Address,
         usingApplicationKey key: ApplicationKey, sequence: UInt32, andIvIndex ivIndex: IvIndex) {
        self.source = source
        self.destination = destination
        self.accessPdu = message.accessPdu
        
        // The nonce type is 0x01 for messages signed with Application Key and
        // 0x02 for messages signed using Device Key (Configuration Messages).
        let type: UInt8 = 0x01
        // ASZMIC is set to 1 for messages that shall be sent with high security
        // (64-bit TransMIC). This is possible only for Segmented Access Messages.
        let aszmic: UInt8 = message.security == .high && (message.accessPdu.count > 11 || message.isSegmented)  ? 1 : 0
        // SEQ is 24-bit value, in Big Endian.
        let seq = (Data() + sequence.bigEndian).dropFirst()
        
        let nonce = Data([type, aszmic << 7]) + seq
            + source.bigEndian
            + destination.bigEndian
            + ivIndex.index.bigEndian
        
        self.aid = key.aid
        self.sequence = sequence
        self.transportMicSize = aszmic == 0 ? 4 : 8
        self.transportPdu = OpenSSLHelper().calculateCCM(message.accessPdu, withKey: key.key, nonce: nonce,
                                                         andMICSize: transportMicSize)
    }
    
    init(fromConfigMessage message: ConfigMessage, sentFrom source: Address, to destination: Address,
         usingDeviceKey key: Data, sequence: UInt32, andIvIndex ivIndex: IvIndex) {
        self.source = source
        self.destination = destination
        self.accessPdu = message.accessPdu
        
        // The nonce type is 0x01 for messages signed with Application Key and
        // 0x02 for messages signed using Device Key (Configuration Messages).
        let type: UInt8 = 0x02
        // ASZMIC is set to 1 for messages that shall be sent with high security
        // (64-bit TransMIC). This is possible only for Segmented Access Messages.
        let aszmic: UInt8 = message.security == .high && (message.accessPdu.count > 11 || message.isSegmented)  ? 1 : 0
        // SEQ is 24-bit value, in Big Endian.
        let seq = (Data() + sequence.bigEndian).dropFirst()
        
        let nonce = Data([type, aszmic << 7]) + seq
            + source.bigEndian
            + destination.bigEndian
            + ivIndex.index.bigEndian
        
        self.aid = nil
        self.sequence = sequence
        self.transportMicSize = aszmic == 0 ? 4 : 8
        self.transportPdu = OpenSSLHelper().calculateCCM(message.accessPdu, withKey: key, nonce: nonce,
                                                         andMICSize: transportMicSize)
    }
    
    /// This method tries to decode teh Access Message using a matching Application Key
    /// or the node's Device Key, based onthe `aid` field value.
    ///
    /// - parameter accessMessage: The Lower Transport Layer Access Message received.
    /// - parameter meshNetwork: The mesh network for which the PDU should be decoded.
    /// - returns: The Upper Transport Layer PDU, of `nil` if none of the keys worked.
    static func decode(_ accessMessage: AccessMessage, for meshNetwork: MeshNetwork) -> UpperTransportPdu? {
        if let aid = accessMessage.aid {
            for applicationKey in meshNetwork.applicationKeys {
                if aid == applicationKey.aid,
                    let pdu = UpperTransportPdu(fromLowerTransportAccessMessage: accessMessage, usingKey: applicationKey.key) {
                    return pdu
                }
                if let oldAid = applicationKey.oldAid, oldAid == applicationKey.aid, let key = applicationKey.oldKey,
                    let pdu = UpperTransportPdu(fromLowerTransportAccessMessage: accessMessage, usingKey: key) {
                    return pdu
                }
            }
        } else {
            if let node = meshNetwork.node(withAddress: accessMessage.destination) {
                let deviceKey = node.deviceKey
                return UpperTransportPdu(fromLowerTransportAccessMessage: accessMessage, usingKey: deviceKey)
            }
        }
        return nil
    }
    
}
