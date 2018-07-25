//
//  ModelSubscriptionDeleteMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 16/05/2018.
//
import Foundation


public struct ModelSubscriptionDeleteMessage {
    var opcode  : Data
    var payload : Data
    
    public init(withElementAddress anElementAddress: Data,
                subscriptionAddress aSubscriptionAddress: Data,
                andModelIdentifier aModelIdentifier: Data) {
        
        opcode = Data([0x80, 0x1C])
        payload = Data()
        payload.append(Data([anElementAddress[1], anElementAddress[0]]))
        payload.append(Data([aSubscriptionAddress[1], aSubscriptionAddress[0]]))
        if aModelIdentifier.count == 2 {
            payload.append(Data([aModelIdentifier[1], aModelIdentifier[0]]))
        } else {
            payload.append(Data([aModelIdentifier[1], aModelIdentifier[0],
                                 aModelIdentifier[3], aModelIdentifier[2]]))
        }
    }

    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        let deviceKey = aState.deviceKeyForUnicast(aDestinationAddress)
        let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, deviceKey: deviceKey!, netKey: aState.netKey, seq: SequenceNumber(), ivIndex: aState.IVIndex, source: aState.unicastAddress, andDst: aDestinationAddress)
        let networkPDU = accessMessage.assembleNetworkPDU()
        return networkPDU
    }
}
