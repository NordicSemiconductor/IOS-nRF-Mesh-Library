//
//  ConfigNetKeyStatus.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 27/06/2019.
//

import Foundation

public struct ConfigNetKeyStatus: ConfigNetKeyMessage {
    public static let opCode: UInt32 = 0x8044
    
    public var parameters: Data? {
        return Data([status.rawValue]) + encodeNetKeyIndex()
    }
    
    public var isSegmented: Bool {
        return true
    }
    
    public let networkKeyIndex: KeyIndex
    /// The status of the App Key operation.
    public let status: ConfigKeyStatus
    
    public init(networkKey: NetworkKey, status: ConfigKeyStatus) {
        self.networkKeyIndex = networkKey.index
        self.status = status
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 3 else {
            return nil
        }
        guard let status = ConfigKeyStatus(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        self.networkKeyIndex = ConfigNetKeyStatus.decodeNetKeyIndex(from: parameters, at: 1)
    }
    
}
