//
//  ConfigAppKeyDelete.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 27/06/2019.
//

import Foundation

public struct ConfigAppKeyDelete: ConfigAppKeyMessage {
    public static let opCode: UInt32 = 0x8000
    
    public var parameters: Data? {
        return encodeNetKeyAndAppKeyIndex()
    }
    
    public var isSegmented: Bool {
        return false
    }
    
    public let networkKeyIndex: KeyIndex
    public let applicationKeyIndex: KeyIndex
    
    public init(applicationKey: ApplicationKey) {
        self.applicationKeyIndex = applicationKey.index
        self.networkKeyIndex = applicationKey.boundNetworkKey.index
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 3 else {
            return nil
        }
        (networkKeyIndex, applicationKeyIndex) = ConfigAppKeyAdd.decodeNetKeyAndAppKeyIndex(from: parameters, at: 0)
    }
    
}