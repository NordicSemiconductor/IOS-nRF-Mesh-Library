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
    let source: Address?
    /// Destination Address.
    let destination: Address
    /// The Access Layer data.
    let accessPdu: Data
    /// The raw data of Upper Transport Layer PDU.
    let transportPdu: Data
    
    init?(fromLowerTransportAccessMessage accessMessage: AccessMessage, usingKey key: Data) {
        let micSize = Int(accessMessage.transportMicSize)
        let pduSize = accessMessage.upperTransportPdu.count
        let mic = accessMessage.upperTransportPdu.subdata(in: pduSize - micSize..<pduSize)
        
        let type: UInt8 = accessMessage.aid != 0 ? 0x01 : 0x02
        let aszmic: UInt8 = micSize == 4 ? 0 : 1
        let seq = (Data() + accessMessage.sequence.bigEndian).dropFirst()
        
        let nonce = Data([type, aszmic << 7]) + seq
            + accessMessage.source!.bigEndian
            + accessMessage.destination.bigEndian
            + accessMessage.networkKey.ivIndex.index.bigEndian
        
        guard let decryptedData = OpenSSLHelper().calculateDecryptedCCM(accessMessage.upperTransportPdu,
                                                                        withKey: key, nonce: nonce, andMIC: mic) else {
                                                                            return nil
        }
        source = accessMessage.source
        destination = accessMessage.destination
        transportPdu = accessMessage.upperTransportPdu
        accessPdu = decryptedData
    }
    
    init(fromMeshMessage message: MeshMessage, destination: Address) {
        self.source = nil
        self.destination = destination
        self.accessPdu = message.accessPdu
        // TODO: Finish this
        self.transportPdu = Data()
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
