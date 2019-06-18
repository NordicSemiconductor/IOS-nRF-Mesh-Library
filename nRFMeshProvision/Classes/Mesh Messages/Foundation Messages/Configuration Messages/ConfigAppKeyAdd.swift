//
//  ConfigAppKeyAdd.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 12/06/2019.
//

import Foundation

public struct ConfigAppKeyAdd: ConfigAppKeyMessage {
    
    public let opCode: UInt32 = 0x00
    public var parameters: Data? {
        return encodeNetKeyAndAppKeyIndex() + key
    }
    
    public var isSegmented: Bool {
        return true
    }
    
    public let networkKeyIndex: KeyIndex
    public let applicationKeyIndex: KeyIndex
    /// The 128-bit Application Key data.
    public let key: Data
    
    public init(applicationKey: ApplicationKey) {
        self.applicationKeyIndex = applicationKey.index
        self.networkKeyIndex = applicationKey.boundNetworkKey.index
        self.key = applicationKey.key
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 19 else {
            return nil
        }
        (networkKeyIndex, applicationKeyIndex) = ConfigAppKeyAdd.decodeNetKeyAndAppKeyIndex(from: parameters, at: 0)
        key = parameters.suffix(from: 3)
    }
    
}
