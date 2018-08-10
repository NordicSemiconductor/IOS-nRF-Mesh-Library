//
//  GenericOnOffStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 24/05/2018.
//

import Foundation

public struct GenericOnOffStatusMessage {
    public var sourceAddress: Data
    public var onOffStatus: Data
    
    public init(withPayload aPayload: Data, andSoruceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        onOffStatus = Data([aPayload[0]])
    }
}
