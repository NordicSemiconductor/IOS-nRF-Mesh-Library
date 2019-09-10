//
//  ConfigVendorModelAppList.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 29/07/2019.
//

import Foundation

public struct ConfigVendorModelAppList: ConfigModelAppList, ConfigVendorModelMessage {
    public static let opCode: UInt32 = 0x804E
    
    public var parameters: Data? {
        let data = Data([status.rawValue]) + elementAddress + companyIdentifier + modelIdentifier
        return data + encode(indexes: applicationKeyIndexes[...])
    }
    
    public let status: ConfigMessageStatus
    public let elementAddress: Address
    public let modelIdentifier: UInt16
    public let companyIdentifier: UInt16
    public let applicationKeyIndexes: [KeyIndex]
    
    public init(responseTo request: ConfigVendorModelAppGet, with applicationKeys: [ApplicationKey]) {
        self.elementAddress = request.elementAddress
        self.modelIdentifier = request.modelIdentifier
        self.companyIdentifier = request.companyIdentifier
        self.applicationKeyIndexes = applicationKeys.map { return $0.index }
        self.status = .success
    }
    
    public init(responseTo request: ConfigVendorModelAppGet, with status: ConfigMessageStatus) {
        self.elementAddress = request.elementAddress
        self.modelIdentifier = request.modelIdentifier
        self.companyIdentifier = request.companyIdentifier
        self.applicationKeyIndexes = []
        self.status = status
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 7 else {
            return nil
        }
        guard let status = ConfigMessageStatus(rawValue: 0) else {
            return nil
        }
        self.status = status
        elementAddress = parameters.read(fromOffset: 1)
        companyIdentifier = parameters.read(fromOffset: 3)
        modelIdentifier = parameters.read(fromOffset: 5)
        applicationKeyIndexes = ConfigSIGModelAppList.decode(indexesFrom: parameters, at: 7)
    }
}
