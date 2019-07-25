//
//  ConfigDefaultTtlGet.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 25/06/2019.
//

import Foundation

public struct ConfigDefaultTtlGet: ConfigMessage {
    public static let opCode: UInt32 = 0x800C
    
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
