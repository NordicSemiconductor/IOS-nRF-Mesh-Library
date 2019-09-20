//
//  GenericOnPowerUpGet.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 23/08/2019.
//

import Foundation

public struct GenericOnPowerUpGet: AcknowledgedGenericMessage {
    public static let opCode: UInt32 = 0x8211
    public static let responseType: StaticMeshMessage.Type = GenericOnPowerUpStatus.self
    
    public var parameters: Data? {
        return nil
    }
    
    public init() {
        // Empty
    }
    
    public init?(parameters: Data) {
        guard parameters.isEmpty else {
            return nil
        }
    }
    
}

