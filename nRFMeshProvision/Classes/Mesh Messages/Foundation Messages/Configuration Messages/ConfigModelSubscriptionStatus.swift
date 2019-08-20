//
//  ConfigModelSubscriptionStatus.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 26/07/2019.
//

import Foundation

public struct ConfigModelSubscriptionStatus: ConfigStatusMessage, ConfigAddressMessage, ConfigAnyModelMessage {
    public static let opCode: UInt32 = 0x801F
    
    public var parameters: Data? {
        let data = Data([status.rawValue]) + elementAddress + address
        if let companyIdentifier = companyIdentifier {
            return data + companyIdentifier + modelIdentifier
        } else {
            return data + modelIdentifier
        }
    }
    
    public var status: ConfigMessageStatus
    public let address: Address
    public let elementAddress: Address
    public let modelIdentifier: UInt16
    public let companyIdentifier: UInt16?
    
    public init(confirmAdding group: Group, to model: Model, withStatus status: ConfigMessageStatus) {
        self.status = status
        self.address = group.address.address
        self.elementAddress = model.parentElement.unicastAddress
        self.modelIdentifier = model.modelIdentifier
        self.companyIdentifier = model.companyIdentifier
    }
    
    public init(confirmDeleting group: Group, to model: Model, withStatus status: ConfigMessageStatus) {
        self.status = status
        self.address = group.address.address
        self.elementAddress = model.parentElement.unicastAddress
        self.modelIdentifier = model.modelIdentifier
        self.companyIdentifier = model.companyIdentifier
    }
    
    public init(confirmDeletingAllFrom model: Model, withStatus status: ConfigMessageStatus) {
        self.status = status
        self.address = Address.unassignedAddress
        self.elementAddress = model.parentElement.unicastAddress
        self.modelIdentifier = model.modelIdentifier
        self.companyIdentifier = model.companyIdentifier
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
        address = parameters.read(fromOffset: 3)
        if parameters.count == 9 {
            companyIdentifier = parameters.read(fromOffset: 5)
            modelIdentifier = parameters.read(fromOffset: 7)
        } else {
            companyIdentifier = nil
            modelIdentifier = parameters.read(fromOffset: 5)
        }
    }
}
