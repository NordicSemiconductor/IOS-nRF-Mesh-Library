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
        return Data([status.rawValue]) + encodeNetKeyIndex() + encode(indexes: applicationKeyIndexes[...])
    }
    
    public var isSegmented: Bool {
        return false
    }
    
    public let networkKeyIndex: KeyIndex
    /// Application Key Indexes bound to the Network Key known to the Node.
    public let applicationKeyIndexes: [KeyIndex]
    /// Operation status.
    public let status: ConfigMessageStatus
    
    public init(networkKey: NetworkKey, applicationKeys: [ApplicationKey], status: ConfigMessageStatus) {
        self.networkKeyIndex = networkKey.index
        self.applicationKeyIndexes = applicationKeys.map { return $0.index }
        self.status = status
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 3 else {
            return nil
        }
        guard let status = ConfigMessageStatus(rawValue: 0) else {
            return nil
        }
        self.status = status
        self.networkKeyIndex = ConfigAppKeyList.decodeNetKeyIndex(from: parameters, at: 1)
        self.applicationKeyIndexes = ConfigAppKeyList.decode(indexesFrom: parameters, at: 3)
    }
}
