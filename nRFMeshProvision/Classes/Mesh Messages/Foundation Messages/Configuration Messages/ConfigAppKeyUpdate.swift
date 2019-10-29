//
//  ConfigAppKeyUpdate.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 14/06/2019.
//

import Foundation

public struct ConfigAppKeyUpdate: AcknowledgedConfigMessage, ConfigNetAndAppKeyMessage {
    public static let opCode: UInt32 = 0x01
    public static let responseType: StaticMeshMessage.Type = ConfigAppKeyStatus.self
    
    public var parameters: Data? {
        return encodeNetAndAppKeyIndex() + key
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
        (networkKeyIndex, applicationKeyIndex) = ConfigAppKeyUpdate.decodeNetAndAppKeyIndex(from: parameters, at: 0)
        key = parameters.subdata(in: 3..<19)
    }
    
}
