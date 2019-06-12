//
//  ConfigAppKeyAdd.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 12/06/2019.
//

import Foundation

public struct ConfigAppKeyAdd: ConfigMessage {
    public let opCode: UInt32 = 0x00
    public var parameters: Data {
        let networkKey = applicationKey.boundNetworkKey
        let netKeyIndexAndAppKeyIndex: UInt32 = UInt32(networkKey.index) << 12 | UInt32(applicationKey.index)
        let keyIndexes = (Data() + netKeyIndexAndAppKeyIndex).dropLast()
        return keyIndexes + applicationKey.key
    }
    
    /// The Application Key to be added to the Node.
    public let applicationKey: ApplicationKey
    
    init(applicationKey: ApplicationKey) {
        self.applicationKey = applicationKey
    }
    
}
