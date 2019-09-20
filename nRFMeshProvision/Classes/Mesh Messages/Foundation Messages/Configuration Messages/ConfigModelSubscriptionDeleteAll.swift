//
//  ConfigModelSubscriptionDeleteAll.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 26/07/2019.
//

import Foundation

public struct ConfigModelSubscriptionDeleteAll: AcknowledgedConfigMessage, ConfigAnyModelMessage {
    public static let opCode: UInt32 = 0x801D
    public static let responseType: StaticMeshMessage.Type = ConfigModelSubscriptionStatus.self
    
    public var parameters: Data? {
        let data = Data() + elementAddress
        if let companyIdentifier = companyIdentifier {
            return data + companyIdentifier + modelIdentifier
        } else {
            return data + modelIdentifier
        }
    }
    
    public let elementAddress: Address
    public let modelIdentifier: UInt16
    public let companyIdentifier: UInt16?
    
    public init(from model: Model) {
        self.elementAddress = model.parentElement.unicastAddress
        self.modelIdentifier = model.modelIdentifier
        self.companyIdentifier = model.companyIdentifier
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 4 || parameters.count == 6 else {
            return nil
        }
        elementAddress = parameters.read(fromOffset: 0)
        if parameters.count == 6 {
            companyIdentifier = parameters.read(fromOffset: 2)
            modelIdentifier = parameters.read(fromOffset: 4)
        } else {
            companyIdentifier = nil
            modelIdentifier = parameters.read(fromOffset: 2)
        }
    }
}
