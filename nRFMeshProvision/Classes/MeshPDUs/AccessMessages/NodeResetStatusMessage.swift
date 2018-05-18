//
//  NodeResetStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 18/05/2018.
//

import Foundation

public struct NodeResetStatusMessage {
    public var sourceAddress: Data
    
    public init(withPayload aPayload: Data, andSoruceAddress srcAddress: Data) {
        sourceAddress = srcAddress
    }
}
