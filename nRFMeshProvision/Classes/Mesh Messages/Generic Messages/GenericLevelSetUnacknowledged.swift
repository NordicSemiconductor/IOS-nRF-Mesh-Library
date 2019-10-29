//
//  GenericLevelSetUnacknowledged.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 23/08/2019.
//

import Foundation

public struct GenericLevelSetUnacknowledged: GenericMessage, TransactionMessage, TransitionMessage {
    public static let opCode: UInt32 = 0x8207
    
    public var tid: UInt8!
    public var parameters: Data? {
        let data = Data() + level + tid
        if let transitionTime = transitionTime, let delay = delay {
            return data + transitionTime.rawValue + delay
        } else {
            return data
        }
    }
    
    /// The target value of the Generic Level state.
    public let level: Int16
    
    public let transitionTime: TransitionTime?
    public let delay: UInt8?
    
    /// Creates the Generic Level Set Unacknowledged message.
    ///
    /// - parameter level: The target value of the Generic Level state.
    public init(level: Int16) {
        self.level = level
        self.transitionTime = nil
        self.delay = nil
    }
    
    /// Creates the Generic Level Set Unacknowledged message.
    ///
    /// - parameters:
    ///   - level: The target value of the Generic Level state.
    ///   - transitionTime: The time that an element will take to transition
    ///                     to the target state from the present state.
    ///   - delay: Message execution delay in 5 millisecond steps.
    public init(level: Int16, transitionTime: TransitionTime, delay: UInt8) {
        self.level = level
        self.transitionTime = transitionTime
        self.delay = delay
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 3 || parameters.count == 5 else {
            return nil
        }
        level = parameters.read(fromOffset: 0)
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

