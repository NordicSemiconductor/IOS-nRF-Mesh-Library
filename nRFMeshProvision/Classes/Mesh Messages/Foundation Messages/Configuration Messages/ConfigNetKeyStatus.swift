//
//  ConfigNetKeyStatus.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 27/06/2019.
//

import Foundation

public struct ConfigNetKeyStatus: ConfigNetKeyMessage, ConfigStatusMessage {
    public static let opCode: UInt32 = 0x8044
    
    public var parameters: Data? {
        return Data([status.rawValue]) + encodeNetKeyIndex()
    }
    
    public let networkKeyIndex: KeyIndex
    public let status: ConfigMessageStatus
    
    public init(confirmAdding networkKey: NetworkKey, withStatus status: ConfigMessageStatus) {
        self.networkKeyIndex = networkKey.index
        self.status = status
    }
    
    public init(confirmDeleting networkKey: NetworkKey, withStatus status: ConfigMessageStatus) {
        self.init(confirmAdding: networkKey, withStatus: status)
    }
    
    public init(confirmUpdating networkKey: NetworkKey, withStatus status: ConfigMessageStatus) {
        self.init(confirmAdding: networkKey, withStatus: status)
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 3 else {
            return nil
        }
        guard let status = ConfigMessageStatus(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        self.networkKeyIndex = ConfigNetKeyStatus.decodeNetKeyIndex(from: parameters, at: 1)
    }
    
}
