//
//  ConfigModelAppStatus.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 02/07/2019.
//

import Foundation

public struct ConfigModelAppStatus: ConfigAppKeyMessage, ConfigAnyModelMessage, ConfigStatusMessage {
    public static let opCode: UInt32 = 0x803E
    
    public var parameters: Data? {
        let data = Data([status.rawValue]) + elementAddress + applicationKeyIndex + modelIdentifier
        if let companyIdentifier = companyIdentifier {
            return data + companyIdentifier
        } else {
            return data
        }
    }
    
    public var isSegmented: Bool {
        return false
    }
    
    public let applicationKeyIndex: KeyIndex
    public let elementAddress: Address
    public let modelIdentifier: UInt16
    public let companyIdentifier: UInt16?
    public let status: ConfigMessageStatus
    
    public init(applicationKey: ApplicationKey, to model: Model, status: ConfigMessageStatus) {
        self.applicationKeyIndex = applicationKey.index
        self.elementAddress = model.parentElement.unicastAddress
        self.modelIdentifier = model.modelIdentifier
        self.companyIdentifier = model.companyIdentifier
        self.status = status
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 7 || parameters.count == 9 else {
            return nil
        }
        guard let status = ConfigMessageStatus(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        elementAddress = parameters.read(fromOffset: 1)
        applicationKeyIndex = parameters.read(fromOffset: 3)
        modelIdentifier = parameters.read(fromOffset: 5)
        if parameters.count == 9 {
            companyIdentifier = parameters.read(fromOffset: 7)
        } else {
            companyIdentifier = nil
        }
    }
}

