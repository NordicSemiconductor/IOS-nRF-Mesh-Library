//
//  DefaultTTLStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 30/04/2018.
//

import Foundation

public struct DefaultTTLStatusMessage {
    public var sourceAddress: Data
    public var defaultTTL: Data

    public init(withPayload aPayload: Data, andSoruceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        defaultTTL = Data([aPayload[0]])
    }
}

