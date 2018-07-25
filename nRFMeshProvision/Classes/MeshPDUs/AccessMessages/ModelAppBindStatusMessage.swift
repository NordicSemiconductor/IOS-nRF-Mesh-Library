//
//  ModelAppStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 13/04/2018.
//

import Foundation

public struct ModelAppBindStatusMessage {
    public var sourceAddress: Data
    public var statusCode: MessageStatusCodes
    public var elementAddress: Data
    public var appkeyIndex: Data
    public var modelIdentifier: Data
    
    public init(withPayload aPayload: Data, andSoruceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        if let aStatusCode = MessageStatusCodes(rawValue: aPayload[0]) {
            statusCode = aStatusCode
        } else {
            statusCode = .success
        }
        elementAddress = aPayload[1...2]
        appkeyIndex = aPayload[3...4]
        if aPayload.count == 9 {
            //Vendor model
            modelIdentifier = aPayload[5...8]
        } else {
            //Sig model
            modelIdentifier = aPayload[5...6]
        }
    }
}
