//
//  AppKeyStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/04/2018.
//

import Foundation

public struct AppKeyStatusMessage {
    public var sourceAddress: Data
    public var statusCode: MessageStatusCodes
    public var netKeyIndex: Data
    public var appKeyIndex: Data

    public init(withPayload aPayload: Data, andSoruceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        if let aStatusCode = MessageStatusCodes(rawValue: aPayload[0]) {
            statusCode = aStatusCode
        } else {
            statusCode = .success
        }
        netKeyIndex = Data()
        appKeyIndex = Data()

        //Unpack netKey and appkey indices
        appKeyIndex.append(aPayload[1] >> 4)
        appKeyIndex.append(aPayload[1] << 4 | aPayload[2] >> 4)
        netKeyIndex.append(aPayload[2] & 0x0F)
        netKeyIndex.append(aPayload[3])
    }
}
