//
//  GenericOnOffGet.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/08/2019.
//

import Foundation

public struct GenericOnOffGet: StaticMeshMessage {
    public static let opCode: UInt32 = 0x8201
    
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
