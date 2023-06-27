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

internal struct UpperTransportPdu {
    /// The Mesh Message that is being sent, or `nil`, when the message
    /// was received.
    let message: MeshMessage?
    /// Whether sending this message has been initiated by the user.
    let userInitiated: Bool
    /// Source Address.
    let source: Address
    /// Destination Address.
    let destination: MeshAddress
    /// 6-bit Application Key identifier. This field is set to `nil`
    /// if the message is signed with a Device Key instead.
    let aid: UInt8?
    /// The sequence number used to encode this message.
    let sequence: UInt32
    /// The IV Index used to encode this message.
    let ivIndex: UInt32
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
            + accessMessage.ivIndex.bigEndian
        
        guard let decryptedData = Crypto.decrypt(encryptedData,
                                                 withEncryptionKey: key, nonce: nonce, andMIC: mic,
                                                 withAdditionalData: virtualGroup?.address.virtualLabel?.data) else {
             return nil
        }
        source = accessMessage.source
        destination = virtualGroup?.address ?? MeshAddress(accessMessage.destination)
        aid = accessMessage.aid
        transportMicSize = accessMessage.transportMicSize
        transportPdu = accessMessage.upperTransportPdu
        accessPdu = decryptedData
        sequence = accessMessage.sequence
        ivIndex = accessMessage.ivIndex
        message = nil
        userInitiated = false
    }
    
    init(fromAccessPdu pdu: AccessPdu, usingKeySet keySet: KeySet,
         sequence: UInt32, andIvIndex ivIndex: IvIndex) {
        self.message = pdu.message
        self.userInitiated = pdu.userInitiated
        self.source = pdu.source
        self.destination = pdu.destination
        self.sequence = sequence
        self.ivIndex = ivIndex.transmitIndex
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
        
        let nonce = Data([type, aszmic << 7]) + seq
            + self.source.bigEndian
            + self.destination.address.bigEndian
            + self.ivIndex.bigEndian
        
        self.transportMicSize = aszmic == 0 ? 4 : 8
        self.transportPdu = Crypto.encrypt(accessPdu, withEncryptionKey: keySet.accessKey,
                                           nonce: nonce, andMICSize: transportMicSize,
                                           withAdditionalData: pdu.destination.virtualLabel?.data)
    }
    
    /// This method tries to decode the Access Message using a matching Application Key
    /// based on the `aid` field value, or the Device Key of the local or source Node.
    ///
    /// - parameters:
    ///   - accessMessage: The Lower Transport Layer Access Message received.
    ///   - meshNetwork: The mesh network for which the PDU should be decoded.
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
                // If the message was not sent to a Virtual Address, just add nil to the
                // matching groups. That way it will be decoded once with group = nil.
                matchingGroups = [nil]
            }
            // Go through all the Application Keys bound to the Network Key that the message
            // was decoded with.
            for applicationKey in meshNetwork.applicationKeys.boundTo(accessMessage.networkKey) {
                // The matchingGroups contains either a list of Virtual Groups, or a single nil.
                for group in matchingGroups {
                    // Each time try decoding using the new, or the old key (if such exist)
                    // when the generated aid matches the one sent in the message.
                    if aid == applicationKey.aid,
                       let pdu = UpperTransportPdu(fromLowerTransportAccessMessage: accessMessage,
                                                   usingKey: applicationKey.key, for: group) {
                        let keySet = AccessKeySet(applicationKey: applicationKey)
                        return (pdu, keySet)
                    }
                    if let oldAid = applicationKey.oldAid, aid == oldAid,
                       let key = applicationKey.oldKey,
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
               let deviceKey = node.deviceKey,
               let pdu = UpperTransportPdu(fromLowerTransportAccessMessage: accessMessage,
                                           usingKey: deviceKey),
               let keySet = DeviceKeySet(networkKey: accessMessage.networkKey, node: node) {
                return (pdu, keySet)
            }
            // On the other hand, if another Provisioner is sending Config Messages,
            // they will be signed using the target Node Device Key instead.
            if let node = meshNetwork.node(withAddress: accessMessage.destination),
               let deviceKey = node.deviceKey,
               let pdu = UpperTransportPdu(fromLowerTransportAccessMessage: accessMessage,
                                           usingKey: deviceKey),
               let keySet = DeviceKeySet(networkKey: accessMessage.networkKey, node: node) {
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
