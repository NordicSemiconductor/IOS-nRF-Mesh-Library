//
//  GenericOnOffSetUnacknowledged.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 22/08/2019.
//

import Foundation

public struct GenericOnOffSetUnacknowledged: StaticMeshMessage, TransactionMessage {
    public static let opCode: UInt32 = 0x8203
    
    public var tid: UInt8!
    public var parameters: Data? {
        let data = Data([isOn ? 0x01 : 0x00, tid])
        if let transitionTime = transitionTime, let delay = delay {
            return data + transitionTime.rawValue + delay
        } else {
            return data
        }
    }
    
    /// The new state of Generic OnOff Server.
    public let isOn: Bool
    /// The Transition Time field identifies the time that an element will
    /// take to transition to the target state from the present state.
    public let transitionTime: TransitionTime?
    /// Message execution delay in 5 millisecond steps.
    public let delay: UInt8?
    
    /// Creates the Generic OnOff Set message.
    ///
    /// - parameter isOn: The target value of the Generic OnOff state.
    public init(_ isOn: Bool) {
        self.isOn = isOn
        self.transitionTime = nil
        self.delay = nil
    }
    
    /// Creates the Generic OnOff Set message.
    ///
    /// - parameters:
    ///   - isOn: The target value of the Generic OnOff state.
    ///   - transitionTime: The time that an element will take to transition
    ///                     to the target state from the present state.
    ///   - delay: Message execution delay in 5 millisecond steps.
    public init(_ isOn: Bool, transitionTime: TransitionTime, delay: UInt8) {
        self.isOn = isOn
        self.transitionTime = transitionTime
        self.delay = delay
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 2 || parameters.count == 4 else {
            return nil
        }
        isOn = parameters[0] == 0x01
        tid = parameters[1]
        if parameters.count == 4 {
            transitionTime = TransitionTime(rawValue: parameters[2])
            delay = parameters[3]
        } else {
            transitionTime = nil
            delay = nil
        }
    }
    
}
