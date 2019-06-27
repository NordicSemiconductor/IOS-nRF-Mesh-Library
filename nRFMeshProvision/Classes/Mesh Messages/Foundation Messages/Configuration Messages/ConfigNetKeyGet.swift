//
//  ConfigNetKeyGet.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 27/06/2019.
//

import Foundation

public struct ConfigNetKeyGet: ConfigMessage {
    public static let opCode: UInt32 = 0x8042
    
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
