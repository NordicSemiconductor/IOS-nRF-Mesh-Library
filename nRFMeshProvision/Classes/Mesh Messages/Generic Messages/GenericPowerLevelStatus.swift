//
//  GenericPowerLevelStatus.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 23/08/2019.
//

import Foundation

public struct GenericPowerLevelStatus: GenericMessage, TransitionStatusMessage {
    public static var opCode: UInt32 = 0x8218
    
    public var parameters: Data? {
        let data = Data() + power
        if let targetPower = targetPower, let remainingTime = remainingTime {
            return data + targetPower + remainingTime.rawValue
        } else {
            return data
        }
    }
    
    /// The present value of the Generic Power Actual state.
    public let power: UInt16
    /// The target value of the Generic Power Actual state.
    public let targetPower: UInt16?
    
    public let remainingTime: TransitionTime?
    
    /// Creates the Generic Power Level Status message.
    ///
    /// - parameter power: The present value of the Generic Power Actual state.
    public init(power: UInt16) {
        self.power = power
        self.targetPower = nil
        self.remainingTime = nil
    }
    
    /// Creates the Generic Power Level Status message.
    ///
    /// - parameters:
    ///   - power: The present value of the Generic Power Actual state.
    ///   - targetPower: The target value of the Generic Power Actual state.
    ///   - remainingTime: The time that an element will take to transition
    ///                    to the target state from the present state.
    public init(power: UInt16, targetPower: UInt16, remainingTime: TransitionTime) {
        self.power = power
        self.targetPower = targetPower
        self.remainingTime = remainingTime
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 2 || parameters.count == 5 else {
            return nil
        }
        power = parameters.read(fromOffset: 0)
        if parameters.count == 5 {
            targetPower = parameters.read(fromOffset: 2)
            remainingTime = TransitionTime(rawValue: parameters[4])
        } else {
            targetPower = nil
            remainingTime = nil
        }
    }
}

