//
//  ConfigNetKeyAdd.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 27/06/2019.
//

import Foundation

public struct ConfigNetKeyAdd: AcknowledgedConfigMessage, ConfigNetKeyMessage {
    public static let opCode: UInt32 = 0x8040
    public static let responseType: StaticMeshMessage.Type = ConfigNetKeyStatus.self
    
    public var parameters: Data? {
        return encodeNetKeyIndex() + key
    }
    
    public let networkKeyIndex: KeyIndex
    /// The 128-bit Application Key data.
    public let key: Data
    
    public init(networkKey: NetworkKey) {
        self.networkKeyIndex = networkKey.index
        self.key = networkKey.key
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 18 else {
            return nil
        }
        networkKeyIndex = ConfigNetKeyAdd.decodeNetKeyIndex(from: parameters, at: 0)
        key = parameters.subdata(in: 2..<18)
    }
    
}
