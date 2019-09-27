//
//  UpperTransportPdu.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 28/05/2019.
//

import Foundation

internal struct UpperTransportPdu {
    /// The Mesh Message that is being sent, or `nil`, when the message
    /// was received.
    let message: MeshMessage?
    /// The local Element that is sending the message, or `nil` when the
    /// message was received.
    let localElement: Element?
    /// Source Address.
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
    
    init?(fromLowerTransportAccessMessage accessMessage: AccessMessage,
          usingKey key: Data, for virtualGroup: Group? = nil) {
        let micSize = Int(accessMessage.transportMicSize)
        let encryptedDataSize = accessMessage.upperTransportPdu.count - micSize
        let encryptedData = accessMessage.upperTransportPdu.prefix(upTo: encryptedDataSize)
        let mic = accessMessage.upperTransportPdu.advanced(by: encryptedDataSize)
        
        // The nonce type is 0x01 for messages signed with Application Key and
        // 0x02 for messages signed using Device Key (Configuration Messages).
        let type: UInt8 = accessMessage.aid != nil ? 0x01 : 0x02
        // ASZMIC is set to 1 for messages sent with high security
        // (64-bit TransMIC). This is possible only for Segmented Access Messages.
        let aszmic: UInt8 = micSize == 4 ? 0 : 1
        let seq = (Data() + accessMessage.sequence.bigEndian).dropFirst()
        
        let nonce = Data([type, aszmic << 7]) + seq
            + accessMessage.source.bigEndian
            + accessMessage.destination.bigEndian
            + accessMessage.networkKey.ivIndex.index.bigEndian
        
        guard let decryptedData = OpenSSLHelper().calculateDecryptedCCM(encryptedData,
                  withKey: key, nonce: nonce, andMIC: mic,
                  withAdditionalData: virtualGroup?.address.virtualLabel?.data) else {
             return nil
        }
        source = accessMessage.source
        destination = accessMessage.destination
        aid = accessMessage.aid
        transportMicSize = accessMessage.transportMicSize
        transportPdu = accessMessage.upperTransportPdu
        accessPdu = decryptedData
        sequence = accessMessage.sequence
        message = nil
        localElement = nil
    }
    
    init(fromAccessPdu pdu: AccessPdu,
         usingKeySet keySet: KeySet, sequence: UInt32) {
        self.message = pdu.message
        self.localElement = pdu.localElement
        self.source = pdu.localElement!.unicastAddress
        self.destination = pdu.destination.address
        self.sequence = sequence
        let accessPdu = pdu.accessPdu
        self.accessPdu = accessPdu
        self.aid = keySet.aid
        let security = pdu.message!.security
        
        // The nonce type is 0x01 for messages signed with Application Key and
        // 0x02 for messages signed using Device Key (Configuration Messages).
        let type: UInt8 = aid != nil ? 0x01 : 0x02
        // ASZMIC is set to 1 for messages that shall be sent with high security
        // (64-bit TransMIC). This is possible only for Segmented Access Messages.
        let aszmic: UInt8 = security == .high && (accessPdu.count > 11 || pdu.isSegmented)  ? 1 : 0
        // SEQ is 24-bit value, in Big Endian.
        let seq = (Data() + sequence.bigEndian).dropFirst()
        
        let ivIndex = keySet.networkKey.ivIndex
        let nonce = Data([type, aszmic << 7]) + seq
            + source.bigEndian
            + destination.bigEndian
            + ivIndex.index.bigEndian
        
        self.transportMicSize = aszmic == 0 ? 4 : 8
        self.transportPdu = OpenSSLHelper().calculateCCM(accessPdu, withKey: keySet.accessKey, nonce: nonce,
                                                         andMICSize: transportMicSize,
                                                         withAdditionalData: pdu.destination.virtualLabel?.data)
    }
    
    /// This method tries to decode teh Access Message using a matching Application Key
    /// or the node's Device Key, based onthe `aid` field value.
    ///
    /// - parameter accessMessage: The Lower Transport Layer Access Message received.
    /// - parameter meshNetwork: The mesh network for which the PDU should be decoded.
    /// - returns: The Upper Transport Layer PDU, of `nil` if none of the keys worked.
    static func decode(_ accessMessage: AccessMessage, for meshNetwork: MeshNetwork)
        -> (pdu: UpperTransportPdu, keySet: KeySet)? {
        // Was the message signed using Application Key?
        if let aid = accessMessage.aid {
            // When the message was sent to a Virtual Address, the message must be decoded
            // with the Virtual Label as Additional Data.
            var matchingGroups: [Group?]
            if accessMessage.destination.isVirtual {
                // Find all groups with matching Virtual Address.
                matchingGroups = meshNetwork.groups.filter {
                    $0.address.address == accessMessage.destination
                }
            } else {
                matchingGroups = [nil]
            }
            for applicationKey in meshNetwork.applicationKeys {
                for group in matchingGroups {
                    if aid == applicationKey.aid,
                        let pdu = UpperTransportPdu(fromLowerTransportAccessMessage: accessMessage,
                                                    usingKey: applicationKey.key, for: group) {
                        let keySet = AccessKeySet(applicationKey: applicationKey)
                        return (pdu, keySet)
                    }
                    if let oldAid = applicationKey.oldAid, oldAid == applicationKey.aid, let key = applicationKey.oldKey,
                        let pdu = UpperTransportPdu(fromLowerTransportAccessMessage: accessMessage,
                                                    usingKey: key, for: group) {
                        let keySet = AccessKeySet(applicationKey: applicationKey)
                        return (pdu, keySet)
                    }
                }
            }
        } else {
            // Try decoding using source's Node Device Key. This should work if a status
            // message was sent as a response to a Config Message sent by this Provisioner.
            if let node = meshNetwork.node(withAddress: accessMessage.source),
               let pdu = UpperTransportPdu(fromLowerTransportAccessMessage: accessMessage,
                                           usingKey: node.deviceKey) {
                let keySet = DeviceKeySet(networkKey: accessMessage.networkKey, node: node)
                return (pdu, keySet)
            }
            // On the other hand, if another Provisioner is sending Config Messages,
            // they will be signed using the target Node Device Key instead.
            if let node = meshNetwork.node(withAddress: accessMessage.destination),
               let pdu = UpperTransportPdu(fromLowerTransportAccessMessage: accessMessage,
                                           usingKey: node.deviceKey) {
                let keySet = DeviceKeySet(networkKey: accessMessage.networkKey, node: node)
                return (pdu, keySet)
            }
        }
        return nil
    }
    
}

extension UpperTransportPdu: CustomDebugStringConvertible {
    
    var debugDescription: String {
        let micSize = Int(transportMicSize)
        let encryptedDataSize = transportPdu.count - micSize
        let encryptedData = transportPdu.prefix(upTo: encryptedDataSize)
        let mic = transportPdu.advanced(by: encryptedDataSize)
        return "Upper Transport PDU (encrypted data: 0x\(encryptedData.hex), transMic: 0x\(mic.hex))"
    }
    
}
