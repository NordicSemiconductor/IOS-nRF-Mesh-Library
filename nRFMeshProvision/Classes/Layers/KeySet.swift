//
//  KeySet.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 10/09/2019.
//

import Foundation

internal protocol KeySet {
    /// The Network Key used to encrypt the message.
    var networkKey: NetworkKey { get }
    /// The Access Layer key used to encrypt the message.
    var accessKey: Data { get }
    /// Application Key identifier, or `nil` for Device Key.
    var aid: UInt8? { get }
}

internal struct AccessKeySet: KeySet {
    let applicationKey: ApplicationKey
    
    var networkKey: NetworkKey {
        return applicationKey.boundNetworkKey
    }
    
    var accessKey: Data {
        if case .distributingKeys = networkKey.phase {
            return applicationKey.oldKey ?? applicationKey.key
        }
        return applicationKey.key
    }
    
    var aid: UInt8? {
        if case .distributingKeys = networkKey.phase {
            return applicationKey.oldAid ?? applicationKey.aid
        }
        return applicationKey.aid
    }
}

internal struct DeviceKeySet: KeySet {
    let networkKey: NetworkKey
    let accessKey: Data
    
    var aid: UInt8? = nil
    
    init(networkKey: NetworkKey, deviceKey: Data) {
        self.networkKey = networkKey
        self.accessKey = deviceKey
    }
}

extension AccessKeySet: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "\(applicationKey)"
    }
    
}

extension DeviceKeySet: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "Device Key"
    }
    
}
