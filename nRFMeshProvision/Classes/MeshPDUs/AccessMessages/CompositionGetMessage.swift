//
//  CompositionGetMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 08/03/2018.
//

import Foundation

public struct CompositionGetMessage {
    var opcode: Data
    var payload: Data
    public init() {
        opcode = Data([0x80, 0x08])
        payload = Data([0xFF])
    }

    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        let deviceKey = aState.deviceKeyForUnicast(aDestinationAddress)
        let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, deviceKey: deviceKey!, netKey: aState.netKey, seq: SequenceNumber(), ivIndex: aState.IVIndex, source: aState.unicastAddress, andDst: aDestinationAddress)
        let networkPDU = accessMessage.assembleNetworkPDU()
        return networkPDU
    }
}
