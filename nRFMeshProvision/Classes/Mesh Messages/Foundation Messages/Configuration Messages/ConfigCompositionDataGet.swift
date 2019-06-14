//
//  ConfigCompositionDataGet.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 14/06/2019.
//

import Foundation

public struct ConfigCompositionDataGet: ConfigMessage {
    
    public let opCode: UInt32 = 0x8008
    public var parameters: Data? {
        return Data([page])
    }
    
    /// Page number of the Composition Data to get.
    public let page: UInt8
    
    public init(page: UInt8 = 0) {
        self.page = page
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 1 else {
            return nil
        }
        page = parameters[0]
    }
    
}
