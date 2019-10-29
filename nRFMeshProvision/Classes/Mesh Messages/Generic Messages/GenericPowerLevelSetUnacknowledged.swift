//
//  GenericPowerLevelSetUnacknowledged.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 23/08/2019.
//

import Foundation

public struct GenericPowerLevelSetUnacknowledged: GenericMessage, TransactionMessage, TransitionMessage {
    public static let opCode: UInt32 = 0x8217
    
    public var tid: UInt8!
    public var parameters: Data? {
        let data = Data() + power + tid
        if let transitionTime = transitionTime, let delay = delay {
            return data + transitionTime.rawValue + delay
        } else {
            return data
        }
    }
    
    /// The target value of the Generic Power Actual state.
    public let power: UInt16
    
    public let transitionTime: TransitionTime?
    public let delay: UInt8?
    
    /// Creates the Generic Power Level Set Unacknowledged message.
    ///
    /// The Generic Power Actual state determines the linear percentage of the
    /// maximum power level of an element, representing a range from 0 percent
    /// through 100 percent. The value is derived using the following formula:
    ///
    /// Represented power level [%] = 100 [%] * Generic Power Actual / 65535
    ///
    /// - parameter power: The target value of the Generic Power Actual state.
    public init(power: UInt16) {
        self.power = power
        self.transitionTime = nil
        self.delay = nil
    }
    
    /// Creates the Generic Power Level Set Unacknowledged message.
    ///
    /// The Generic Power Actual state determines the linear percentage of the
    /// maximum power level of an element, representing a range from 0 percent
    /// through 100 percent. The value is derived using the following formula:
    ///
    /// Represented power level [%] = 100 [%] * Generic Power Actual / 65535
    ///
    /// - parameters:
    ///   - power: The target value of the Generic Power Actual state.
    ///   - transitionTime: The time that an element will take to transition
    ///                     to the target state from the present state.
    ///   - delay: Message execution delay in 5 millisecond steps.
    public init(power: UInt16, transitionTime: TransitionTime, delay: UInt8) {
        self.power = power
        self.transitionTime = transitionTime
        self.delay = delay
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 3 || parameters.count == 5 else {
            return nil
        }
        power = parameters.read(fromOffset: 0)
        tid = parameters[2]
        if parameters.count == 5 {
            transitionTime = TransitionTime(rawValue: parameters[3])
            delay = parameters[4]
        } else {
            transitionTime = nil
            delay = nil
        }
    }
    
}

