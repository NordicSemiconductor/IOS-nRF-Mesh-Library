//
//  ConfigModelSubscriptionVirtualAddressDelete.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 26/07/2019.
//

import Foundation
import CoreBluetooth

public struct ConfigModelSubscriptionVirtualAddressDelete: ConfigVirtualLabelMessage, ConfigAnyModelMessage {
    public static let opCode: UInt32 = 0x8021
    
    public var parameters: Data? {
        let data = Data() + elementAddress + virtualLabel.data + modelIdentifier
        if let companyIdentifier = companyIdentifier {
            return data + companyIdentifier
        } else {
            return data
        }
    }
    
    public let virtualLabel: UUID
    public let elementAddress: Address
    public let modelIdentifier: UInt16
    public let companyIdentifier: UInt16?
    
    public init?(group: Group, from model: Model) {
        guard let label = group.address.virtualLabel else {
            return nil
        }
        self.virtualLabel = label
        self.elementAddress = model.parentElement.unicastAddress
        self.modelIdentifier = model.modelIdentifier
        self.companyIdentifier = model.companyIdentifier
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 20 || parameters.count == 24 else {
            return nil
        }
        elementAddress = parameters.read(fromOffset: 0)
        virtualLabel = CBUUID(data: parameters.dropFirst(2).prefix(16)).uuid
        modelIdentifier = parameters.read(fromOffset: 18)
        if parameters.count == 24 {
            companyIdentifier = parameters.read(fromOffset: 20)
        } else {
            companyIdentifier = nil
        }
    }
}

