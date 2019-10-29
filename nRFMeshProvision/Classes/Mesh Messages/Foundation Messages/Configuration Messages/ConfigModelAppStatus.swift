//
//  ConfigModelAppStatus.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 02/07/2019.
//

import Foundation

public struct ConfigModelAppStatus: ConfigAppKeyMessage, ConfigAnyModelMessage, ConfigStatusMessage {
    public static let opCode: UInt32 = 0x803E
    
    public var parameters: Data? {
        let data = Data([status.rawValue]) + elementAddress + applicationKeyIndex
        if let companyIdentifier = companyIdentifier {
            return data + companyIdentifier + modelIdentifier
        } else {
            return data + modelIdentifier
        }
    }
    
    public let applicationKeyIndex: KeyIndex
    public let elementAddress: Address
    public let modelIdentifier: UInt16
    public let companyIdentifier: UInt16?
    public let status: ConfigMessageStatus
    
    public init<T: ConfigAppKeyMessage & ConfigAnyModelMessage>(confirm request: T) {
        self.init(responseTo: request, with: .success)
    }
    
    public init<T: ConfigAppKeyMessage & ConfigAnyModelMessage>(responseTo request: T,
                                                                with status: ConfigMessageStatus) {
        self.applicationKeyIndex = request.applicationKeyIndex
        self.elementAddress = request.elementAddress
        self.modelIdentifier = request.modelIdentifier
        self.companyIdentifier = request.companyIdentifier
        self.status = status
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
        applicationKeyIndex = parameters.read(fromOffset: 3)
        if parameters.count == 9 {
            companyIdentifier = parameters.read(fromOffset: 5)
            modelIdentifier = parameters.read(fromOffset: 7)
        } else {
            companyIdentifier = nil
            modelIdentifier = parameters.read(fromOffset: 5)
        }
    }
}

