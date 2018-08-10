//
//  AppKeySetMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 22/03/2018.
//

import Foundation

public struct AppKeyAddMessage {
    var opcode  : Data
    var payload : Data

    public init(withAppKeyData anAppKeyData: Data, appKeyIndex: Data, netkeyIndex: Data) {
        opcode = Data([0x00])
        payload = Data()
        //Data is packed, second Octet has 4 LSbs of netKeyINdex then 4 MSbs of AppKeyIndex
        //Also all data is octet indexed, so the first 4 MSbs needs to be stripped from both value
        payload.append(Data([netkeyIndex[1]]))
        payload.append(Data([(appKeyIndex[1] << 4) | (netkeyIndex[0] & 0x0F)]))
        payload.append(Data([(appKeyIndex[0] << 4) | (appKeyIndex[1] >> 4)]))
        //First 3 octets are netkey & appkey indices
        //Next is the 16 octets of actual key data
        payload.append(Data(anAppKeyData))
    }
   
    public func assemblePayload(withMeshState aState: MeshState, toAddress aDestinationAddress: Data) -> [Data]? {
        let deviceKey = aState.deviceKeyForUnicast(aDestinationAddress)
        let accessMessage = AccessMessagePDU(withPayload: Data(payload), opcode: opcode, deviceKey: deviceKey!, netKey: aState.netKey, seq: SequenceNumber(), ivIndex: aState.IVIndex, source: aState.unicastAddress, andDst: aDestinationAddress)
        let networkPDU = accessMessage.assembleNetworkPDU()
        return networkPDU
    }
}

