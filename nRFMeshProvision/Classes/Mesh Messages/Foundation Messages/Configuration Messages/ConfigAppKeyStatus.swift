//
//  ConfigAppKeyStatus.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 12/06/2019.
//

import Foundation

public struct ConfigAppKeyStatus: ConfigMessage {
    
    public enum Status: UInt8 {
        case success = 0x00
        case invalidAddress = 0x01
        case invalidModel = 0x02
        case invalidAppKeyIndex = 0x03
        case invalidNetKeyIndex = 0x04
        case insufficientResources = 0x05
        case keyIndexAlreadyStored = 0x06
        case invalidPublishParameters = 0x07
        case notaSubscribeModel = 0x08
        case storageFailure = 0x09
        case featureNotSupported = 0x0A
        case cannotUpdate = 0x0B
        case cannotRemove = 0x0C
        case cannotBind = 0x0D
        case temporarilyUnabletoChangeState = 0x0E
        case cannotSet = 0x0F
        case unspecifiedError = 0x10
        case invalidBinding = 0x11
    }
    
    public let opCode: UInt32 = 0x8003
    public var parameters: Data {
        let networkKey = applicationKey.boundNetworkKey
        let netKeyIndexAndAppKeyIndex: UInt32 = UInt32(networkKey.index) << 12 | UInt32(applicationKey.index)
        let keyIndexes = (Data() + netKeyIndexAndAppKeyIndex).dropLast()
        return Data([status.rawValue]) + keyIndexes
    }
    
    /// The Application Key to be added to the Node.
    public let applicationKey: ApplicationKey
    /// The status.
    public let status: Status
    
    init(applicationKey: ApplicationKey, status: Status) {
        self.applicationKey = applicationKey
        self.status = status
    }
    
}
