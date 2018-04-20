//
//  WhiteListMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 08/03/2018.
//

import Foundation

public enum MeshFilterTypes: UInt8 {
    case whiteList = 0x00
    case blackList = 0x01
}

public struct SetFilterTypeMessage {
    var opcode = Data([0x00])
    var filterType: Data
    
    public init(withFilterType aFilterType: MeshFilterTypes) {
        filterType = Data([aFilterType.rawValue])
    }

    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
//        let deviceKey = aState.deviceKeyForUnicast(aDestinationAddress)
         let controlMessage = ControlMessagePDU(withPayload: filterType, opcode: opcode, netKey: aState.netKey, seq: SequenceNumber(), ivIndex: aState.IVIndex, source: aState.unicastAddress, andDst: aDestinationAddress)
//        let controlMessage = ControlMessagePDU(withPayload: filterType, opcode: opcode, netKey: aState.netKey, seq: Data([0x00, 0x00, 0x01]), ivIndex: aState.IVIndex, source: aState.unicastAddress, andDst: aDestinationAddress)
        let networkPDU = controlMessage.assembleNetworkPDU()
        return networkPDU
    }
}
