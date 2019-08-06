//
//  ConfigGATTProxyGet.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 06/08/2019.
//

import Foundation

public struct ConfigGATTProxyGet: ConfigMessage {
    public static let opCode: UInt32 = 0x8012
    
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
