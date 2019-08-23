//
//  GenericLevelGet.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 23/08/2019.
//

import Foundation

public struct GenericLevelGet: StaticMeshMessage {
    public static let opCode: UInt32 = 0x8205
    
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
