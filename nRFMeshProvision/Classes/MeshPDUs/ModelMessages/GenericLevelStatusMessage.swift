//
//  GenericLevelStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 08/10/2018.
//

import Foundation

public struct GenericLevelStatusMessage {
    public var sourceAddress: Data
    public var levelStatus: Data
    
    public init(withPayload aPayload: Data, andSoruceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        levelStatus = Data([aPayload[0], aPayload[1]])
    }
}
