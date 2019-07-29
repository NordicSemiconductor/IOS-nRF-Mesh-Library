//
//  ConfigSIGModelAppList.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 29/07/2019.
//

import Foundation

public struct ConfigSIGModelAppList: ConfigModelAppList {
    public static let opCode: UInt32 = 0x804C
    
    public var parameters: Data? {
        return Data([status.rawValue]) + elementAddress + modelIdentifier + encode(indexes: applicationKeyIndexes[...])
    }
    
    public let status: ConfigMessageStatus
    public let elementAddress: Address
    public let modelIdentifier: UInt16
    public let applicationKeyIndexes: [KeyIndex]
    
    public init?(for model: Model, applicationKeys: [ApplicationKey], status: ConfigMessageStatus) {
        guard model.companyIdentifier == nil else {
            // Use ConfigVendorModelAppList instead.
            return nil
        }
        self.elementAddress = model.parentElement.unicastAddress
        self.modelIdentifier = model.modelIdentifier
        self.applicationKeyIndexes = applicationKeys.map { return $0.index }
        self.status = status
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 5 else {
            return nil
        }
        guard let status = ConfigMessageStatus(rawValue: 0) else {
            return nil
        }
        self.status = status
        elementAddress = parameters.read(fromOffset: 1)
        modelIdentifier = parameters.read(fromOffset: 3)
        applicationKeyIndexes = ConfigSIGModelAppList.decode(indexesFrom: parameters, at: 5)
    }
}
