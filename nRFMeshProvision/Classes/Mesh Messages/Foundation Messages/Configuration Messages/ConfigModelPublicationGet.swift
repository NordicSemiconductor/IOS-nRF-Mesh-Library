//
//  ConfigModelPublicationGet.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 04/07/2019.
//

import Foundation

public struct ConfigModelPublicationGet: ConfigAnyModelMessage {
    public static let opCode: UInt32 = 0x8018
    
    public var parameters: Data? {
        let data = Data() + elementAddress + modelIdentifier
        if let companyIdentifier = companyIdentifier {
            return data + companyIdentifier
        } else {
            return data
        }
    }
    
    public let elementAddress: Address
    public let modelIdentifier: UInt16
    public let companyIdentifier: UInt16?
    
    public init(for model: Model) {
        self.elementAddress = model.parentElement.unicastAddress
        self.modelIdentifier = model.modelIdentifier
        self.companyIdentifier = model.companyIdentifier
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 4 || parameters.count == 6 else {
            return nil
        }
        elementAddress = parameters.read(fromOffset: 0)
        modelIdentifier = parameters.read(fromOffset: 2)
        if parameters.count == 6 {
            companyIdentifier = parameters.read(fromOffset: 4)
        } else {
            companyIdentifier = nil
        }
    }
}
