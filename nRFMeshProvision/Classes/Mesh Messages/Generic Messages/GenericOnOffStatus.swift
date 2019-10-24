//
//  GenericOnOffStatus.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 22/08/2019.
//

import Foundation

public struct GenericOnOffStatus: GenericMessage, TransitionStatusMessage {
    public static var opCode: UInt32 = 0x8204
    
    public var parameters: Data? {
        let data = Data([isOn ? 0x01 : 0x00])
        if let targetState = targetState, let remainingTime = remainingTime {
            return data + UInt8(targetState ? 0x01 : 0x00) + remainingTime.rawValue
        } else {
            return data
        }
    }
    
    /// The present state of Generic OnOff Server.
    public let isOn: Bool
    /// The target state of Generic OnOff Server.
    public let targetState: Bool?
    
    public let remainingTime: TransitionTime?
    
    /// Creates the Generic OnOff Status message.
    ///
    /// - parameter isOn: The current value of the Generic OnOff state.
    public init(_ isOn: Bool) {
        self.isOn = isOn
        self.targetState = nil
        self.remainingTime = nil
    }
    
    /// Creates the Generic OnOff Status message.
    ///
    /// - parameters:
    ///   - isOn: The current value of the Generic OnOff state.
    ///   - targetState: The target value of the Generic OnOff state.
    ///   - remainingTime: The time that an element will take to transition
    ///                    to the target state from the present state.
    public init(_ isOn: Bool, targetState: Bool, remainingTime: TransitionTime) {
        self.isOn = isOn
        self.targetState = targetState
        self.remainingTime = remainingTime
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 1 || parameters.count == 3 else {
            return nil
        }
        isOn = parameters[0] == 0x01
        if parameters.count == 3 {
            targetState = parameters[1] == 0x01
            remainingTime = TransitionTime(rawValue: parameters[2])
        } else {
            targetState = nil
            remainingTime = nil
        }
    }    
}
