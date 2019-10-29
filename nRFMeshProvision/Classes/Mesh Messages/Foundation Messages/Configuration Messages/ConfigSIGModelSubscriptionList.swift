//
//  ConfigSIGModelSubscriptionList.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 29/07/2019.
//

import Foundation

public struct ConfigSIGModelSubscriptionList: ConfigModelSubscriptionList {
    public static let opCode: UInt32 = 0x802A
    
    public var parameters: Data? {
        let data = Data([status.rawValue]) + elementAddress + modelIdentifier
        return addresses.reduce(data, { data, address in data + address })
    }
    
    public let status: ConfigMessageStatus
    public let elementAddress: Address
    public let modelIdentifier: UInt16
    public let addresses: [Address]
    
    public init(responseTo request: ConfigSIGModelSubscriptionGet, with addresses: [Address]) {
        self.elementAddress = request.elementAddress
        self.modelIdentifier = request.modelIdentifier
        self.addresses = addresses
        self.status = .success
    }
    
    public init(responseTo request: ConfigSIGModelSubscriptionGet, with status: ConfigMessageStatus) {
        self.elementAddress = request.elementAddress
        self.modelIdentifier = request.modelIdentifier
        self.addresses = []
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
        // Read list of addresses.
        var array: [Address] = []
        for offset in stride(from: 5, to: parameters.count, by: 2) {
            array.append(parameters.read(fromOffset: offset))
        }
        addresses = array
    }
}

