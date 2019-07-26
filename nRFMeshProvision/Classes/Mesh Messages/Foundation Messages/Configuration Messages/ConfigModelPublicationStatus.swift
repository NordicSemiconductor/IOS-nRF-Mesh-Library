//
//  ConfigModelPublicationStatus.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 04/07/2019.
//

import Foundation

public struct ConfigModelPublicationStatus: ConfigAnyModelMessage, ConfigStatusMessage {
    public static let opCode: UInt32 = 0x8019
    
    public var parameters: Data? {
        var data = Data([status.rawValue]) + elementAddress + publish.publicationAddress.address
        data += UInt8(publish.index & 0xFF)
        data += UInt8(publish.index >> 8) | UInt8(publish.credentials << 4)
        data += publish.ttl
        data += (publish.periodSteps & 0x3F) | (publish.periodResolution.rawValue >> 6)
        data += (publish.retransmit.count & 0x07) | (publish.retransmit.steps << 3)
        data += modelIdentifier
        if let companyIdentifier = companyIdentifier {
            return data + companyIdentifier
        } else {
            return data
        }
    }
    
    public let elementAddress: Address
    public let modelIdentifier: UInt16
    public let companyIdentifier: UInt16?
    /// Publication data.
    public let publish: Publish
    public let status: ConfigMessageStatus
    
    public init(confirmSetting publish: Publish, to model: Model, withStatus status: ConfigMessageStatus) {
        self.publish = publish
        self.elementAddress = model.parentElement.unicastAddress
        self.modelIdentifier = model.modelIdentifier
        self.companyIdentifier = model.companyIdentifier
        self.status = status
    }
    
    public init(confirmDeletingPublicationFrom model: Model, withStatus status: ConfigMessageStatus) {
        self.init(confirmSetting: Publish(), to: model, withStatus: status)
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 12 || parameters.count == 14 else {
            return nil
        }
        guard let status = ConfigMessageStatus(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        self.elementAddress = parameters.read(fromOffset: 1)
        
        let address: Address = parameters.read(fromOffset: 3)
        let index: KeyIndex = parameters.read(fromOffset: 5) & 0x0FFF
        let flag = Int((parameters[6] & 0x10) >> 4)
        let ttl = parameters[7]
        let periodSteps = parameters[8] & 0x3F
        let periodResolution = Publish.StepResolution(rawValue: parameters[8] >> 6)!
        let count = parameters[9] & 0x07
        let interval = parameters[9] >> 3
        let retransmit = Publish.Retransmit(publishRetransmitCount: count, intervalSteps: interval)
        
        self.publish = Publish(to: address.hex, withKeyIndex: index,
                               friendshipCredentialsFlag: flag, ttl: ttl,
                               periodSteps: periodSteps, periodResolution: periodResolution,
                               retransmit: retransmit)
        self.modelIdentifier = parameters.read(fromOffset: 10)
        if parameters.count == 14 {
            self.companyIdentifier = parameters.read(fromOffset: 12)
        } else {
            self.companyIdentifier = nil
        }
    }
}
