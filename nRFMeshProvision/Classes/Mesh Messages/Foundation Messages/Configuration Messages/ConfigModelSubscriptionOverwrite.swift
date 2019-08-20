//
//  ConfigModelSubscriptionOverwrite.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 26/07/2019.
//

import Foundation

public struct ConfigModelSubscriptionOverwrite: ConfigAddressMessage, ConfigAnyModelMessage {
    public static let opCode: UInt32 = 0x801E
    
    public var parameters: Data? {
        let data = Data() + elementAddress + address
        if let companyIdentifier = companyIdentifier {
            return data + companyIdentifier + modelIdentifier
        } else {
            return data + modelIdentifier
        }
    }
    
    public let address: Address
    public let elementAddress: Address
    public let modelIdentifier: UInt16
    public let companyIdentifier: UInt16?
    
    public init?(group: Group, to model: Model) {
        guard group.address.address.isGroup else {
            // ConfigModelSubscriptionVirtualAddressOverwrite should be used instead.
            return nil
        }
        self.address = group.address.address
        self.elementAddress = model.parentElement.unicastAddress
        self.modelIdentifier = model.modelIdentifier
        self.companyIdentifier = model.companyIdentifier
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 6 || parameters.count == 8 else {
            return nil
        }
        elementAddress = parameters.read(fromOffset: 0)
        address = parameters.read(fromOffset: 2)
        if parameters.count == 8 {
            companyIdentifier = parameters.read(fromOffset: 4)
            modelIdentifier = parameters.read(fromOffset: 6)
        } else {
            companyIdentifier = nil
            modelIdentifier = parameters.read(fromOffset: 4)
        }
    }
}
