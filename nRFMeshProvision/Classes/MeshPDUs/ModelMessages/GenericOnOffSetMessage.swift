//
//  GenericOnOffSetMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 24/05/2018.
//

import Foundation

public struct GenericOnOffSetMessage {
    var opcode  : Data
    var payload : Data

    public init(withTargetState aTargetState: Data) {
            opcode = Data([0x82, 0x02])
        payload = aTargetState
        //Sequence number used as TID
        let tid = Data([SequenceNumber().sequenceData().last!])
        payload.append(tid)
    }

    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        let appKey = aState.appKeys[0].values.first!
        let accessMessage = AccessMessagePDU(withPayload: payload, opcode: opcode, appKey: appKey, netKey: aState.netKey, seq: SequenceNumber(), ivIndex: aState.IVIndex, source: aState.unicastAddress, andDst: aDestinationAddress)
        let networkPDU = accessMessage.assembleNetworkPDU()
        return networkPDU
    }
}
