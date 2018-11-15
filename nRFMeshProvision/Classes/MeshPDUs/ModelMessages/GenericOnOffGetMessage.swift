//
//  GenericOnOffGetMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 24/05/2018.
//

import Foundation

public struct GenericOnOffGetMessage {
    var opcode  : Data
    var payload : Data

    public init() {
        opcode = Data([0x82, 0x01])
        payload = Data()
    }
    
    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        let appKey = aState.appKeys[0].values.first!
        print("assemble generic get payload: \(payload.hexString()) \(opcode.hexString()) to: \(aDestinationAddress.hexString()) with appkey \(appKey.hexString())")
        let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, appKey: appKey, netKey: aState.netKey, seq: SequenceNumber(), ivIndex: aState.IVIndex, source: aState.unicastAddress, andDst: aDestinationAddress)
        let networkPDU = accessMessage.assembleNetworkPDU()
        return networkPDU
    }
}
