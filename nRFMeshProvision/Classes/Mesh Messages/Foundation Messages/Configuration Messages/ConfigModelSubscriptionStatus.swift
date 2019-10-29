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
    
    public let status: ConfigMessageStatus
    public let address: Address
    public let elementAddress: Address
    public let modelIdentifier: UInt16
    public let companyIdentifier: UInt16?
    
    public init<T: ConfigAddressMessage & ConfigAnyModelMessage>(responseTo request: T, with status: ConfigMessageStatus) {
        self.address = request.address
        self.elementAddress = request.elementAddress
        self.modelIdentifier = request.modelIdentifier
        self.companyIdentifier = request.companyIdentifier
        self.status = status
    }
    
    public init<T: ConfigVirtualLabelMessage & ConfigAnyModelMessage>(responseTo request: T, with status: ConfigMessageStatus) {
        self.address = MeshAddress(request.virtualLabel).address
        self.elementAddress = request.elementAddress
        self.modelIdentifier = request.modelIdentifier
        self.companyIdentifier = request.companyIdentifier
        self.status = status
    }
    
    public init(responseTo request: ConfigModelSubscriptionDeleteAll, with status: ConfigMessageStatus) {
        self.address = Address.unassignedAddress
        self.elementAddress = request.elementAddress
        self.modelIdentifier = request.modelIdentifier
        self.companyIdentifier = request.companyIdentifier
        self.status = status
    }
    
    public init(confirmAdding group: Group, to model: Model) {
        self.status = .success
        self.address = group.address.address
        self.elementAddress = model.parentElement.unicastAddress
        self.modelIdentifier = model.modelIdentifier
        self.companyIdentifier = model.companyIdentifier
    }
    
    public init(confirmDeleting address: Address, from model: Model) {
        self.status = .success
        self.address = address
        self.elementAddress = model.parentElement.unicastAddress
        self.modelIdentifier = model.modelIdentifier
        self.companyIdentifier = model.companyIdentifier
    }
    
    public init(confirmDeletingAllFrom model: Model) {
        self.status = .success
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
