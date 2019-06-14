//
//  ConfigAppKeyStatus.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 12/06/2019.
//

import Foundation

public struct ConfigAppKeyStatus: ConfigAppKeyMessage {
    
    // The type of App Key operation.
    public enum Status: UInt8 {
        case success = 0x00
        case invalidAddress = 0x01
        case invalidModel = 0x02
        case invalidAppKeyIndex = 0x03
        case invalidNetKeyIndex = 0x04
        case insufficientResources = 0x05
        case keyIndexAlreadyStored = 0x06
        case invalidPublishParameters = 0x07
        case notASubscribeModel = 0x08
        case storageFailure = 0x09
        case featureNotSupported = 0x0A
        case cannotUpdate = 0x0B
        case cannotRemove = 0x0C
        case cannotBind = 0x0D
        case temporarilyUnableToChangeState = 0x0E
        case cannotSet = 0x0F
        case unspecifiedError = 0x10
        case invalidBinding = 0x11
    }
    
    public let opCode: UInt32 = 0x8003
    public var parameters: Data? {
        return Data([status.rawValue]) + encodeNetKeyAndAppKeyIndex()
    }
    
    public let networkKeyIndex: KeyIndex
    public let applicationKeyIndex: KeyIndex
    /// The status of the App Key operation.
    public let status: Status
    
    public init(applicationKey: ApplicationKey, status: Status) {
        self.applicationKeyIndex = applicationKey.index
        self.networkKeyIndex = applicationKey.boundNetworkKey.index
        self.status = status
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 4 else {
            return nil
        }
        guard let status = Status(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        (networkKeyIndex, applicationKeyIndex) = ConfigAppKeyUpdate.decodeNetKeyAndAppKeyIndex(from: parameters, at: 1)
    }
    
}
