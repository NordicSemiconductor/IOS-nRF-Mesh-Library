//
//  ModelPublicationSetMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 18/04/2018.
//
import Foundation


public struct ModelPublicationSetMessage {
    var opcode  : Data
    var payload : Data
    
    public init(withElementAddress anElementAddress: Data,
                publishAddress aPublishAddress: Data,
                appKeyIndex anAppKeyIndex: Data,
                credentialFlag aCredentialFlag: Bool,
                publishTTL aPublishTTL: Data,
                publishPeriod aPublishPeriod: Data,
                retransmitCount aCount: Data,
                retransmitInterval anInterval: Data,
                andModelIdentifier aModelIdentifier: Data) {
        
        opcode = Data([0x03])
        var credentialFlag: UInt8 = 0x00
        if aCredentialFlag {
            credentialFlag = 0x08
        }
        payload = Data()
        payload.append(Data([anElementAddress[1], anElementAddress[0]]))
        payload.append(Data([aPublishAddress[1], aPublishAddress[0]]))
        payload.append(Data([anAppKeyIndex[1]]))
        payload.append(Data([(anAppKeyIndex[0] << 4) | credentialFlag]))
        payload.append(Data([aPublishTTL[0], aPublishPeriod[0]]))
        let retransmitData = UInt8((aCount[0] << 5) | (anInterval[0] & 0x1F))
        payload.append(Data([retransmitData]))
        if aModelIdentifier.count == 2 {
            payload.append(Data([aModelIdentifier[1], aModelIdentifier[0]]))
        } else {
            payload.append(Data([aModelIdentifier[1], aModelIdentifier[0],
                                 aModelIdentifier[3], aModelIdentifier[2]]))
        }
        print("DBG: publication address payload: \(payload.hexString())")
    }
    
    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        let deviceKey = aState.deviceKeyForUnicast(aDestinationAddress)
        let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, deviceKey: deviceKey!, netKey: aState.netKey, seq: SequenceNumber(), ivIndex: aState.IVIndex, source: aState.unicastAddress, andDst: aDestinationAddress)
        let networkPDU = accessMessage.assembleNetworkPDU()
        return networkPDU
    }
}
