//
//  GenericLevelGetMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 08/10/2018.
//

import Foundation

public struct GenericLevelGetMessage {
    var opcode  : Data
    var payload : Data
    
    public init() {
        opcode = Data([0x82, 0x05])
        payload = Data()
    }
    
    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        let appKey = aState.appKeys[0].values.first!
        let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, appKey: appKey, netKey: aState.netKey, seq: SequenceNumber(), ivIndex: aState.IVIndex, source: aState.unicastAddress, andDst: aDestinationAddress)
        let networkPDU = accessMessage.assembleNetworkPDU()
        return networkPDU
    }
}
