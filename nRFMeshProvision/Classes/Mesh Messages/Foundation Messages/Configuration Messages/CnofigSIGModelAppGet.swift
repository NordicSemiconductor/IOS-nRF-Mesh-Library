//
//  CnofigSIGModelAppGet.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 29/07/2019.
//

import Foundation

public struct ConfigSIGModelAppGet: ConfigModelMessage {
    public static let opCode: UInt32 = 0x804B
    
    public var parameters: Data? {
        return Data() + elementAddress + modelIdentifier
    }
    
    public let elementAddress: Address
    public let modelIdentifier: UInt16
    
    public init?(of model: Model) {
        guard model.companyIdentifier == nil else {
            // Use ConfigVendorModelAppGet instead.
            return nil
        }
        self.elementAddress = model.parentElement.unicastAddress
        self.modelIdentifier = model.modelIdentifier
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 4 else {
            return nil
        }
        elementAddress = parameters.read(fromOffset: 0)
        modelIdentifier = parameters.read(fromOffset: 2)
    }
}

