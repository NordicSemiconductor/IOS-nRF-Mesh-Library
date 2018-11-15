//
//  SceneStoreUnacknowledgedMessage.swift
//  nRFMeshProvision
//
//  Created by Dominique Rau on 18/11/2018.
//

import Foundation

public struct SceneStoreUnacknowledgedMessage {
    var opcode  : Data = Data([0x82, 0x47]);
    var payload : Data
    
    public init(withSceneNumber aSceneNumber: Data) {
        payload = aSceneNumber
    }
    
    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        let appKey = aState.appKeys[0].values.first!
        let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, appKey: appKey, netKey: aState.netKey, seq: SequenceNumber(), ivIndex: aState.IVIndex, source: aState.unicastAddress, andDst: aDestinationAddress)
        let networkPDU = accessMessage.assembleNetworkPDU()
        return networkPDU
    }
}
