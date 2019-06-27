//
//  ConfigAppKeyList.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 27/06/2019.
//

import Foundation

public struct ConfigAppKeyList: ConfigNetKeyMessage {
    public static let opCode: UInt32 = 0x8002
    
    public var parameters: Data? {
        return encodeNetKeyIndex()
    }
    
    public var isSegmented: Bool {
        return false
    }
    
    public let status: ConfigKeyStatus
    public let networkKeyIndex: KeyIndex
    public let applicationKeyIndexes: [KeyIndex]
    
    public init(status: ConfigKeyStatus, networkKey: NetworkKey, applicationKeys: [ApplicationKey]) {
        self.status = status
        self.networkKeyIndex = networkKey.index
        self.applicationKeyIndexes = applicationKeys.map { return $0.index }
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 3 else {
            return nil
        }
        guard let status = ConfigKeyStatus(rawValue: 0) else {
            return nil
        }
        self.status = status
        self.networkKeyIndex = ConfigAppKeyList.decodeNetKeyIndex(from: parameters, at: 1)
        self.applicationKeyIndexes = ConfigAppKeyList.decodeIndexes(from: parameters, at: 3)
    }
}
