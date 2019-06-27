//
//  ConfigNodeResetStatus.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 19/06/2019.
//

import Foundation

public struct ConfigNodeResetStatus: ConfigMessage {
    public static let opCode: UInt32 = 0x804A
    
    public var parameters: Data? {
        return nil
    }
    
    public var isSegmented: Bool {
        return false
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
