//
//  GenericDeltaSet.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 23/08/2019.
//

import Foundation

public struct GenericDeltaSet: GenericMessage, TransactionMessage, TransitionMessage {
    public static let opCode: UInt32 = 0x8209
    
    public var tid: UInt8!
    public var continueTransaction: Bool = true
    public var parameters: Data? {
        let data = Data() + level + tid
        if let transitionTime = transitionTime, let delay = delay {
            return data + transitionTime.rawValue + delay
        } else {
            return data
        }
    }
    
    /// The Delta change of the Generic Level state.
    public let level: Int32
    
    public let transitionTime: TransitionTime?
    public let delay: UInt8?
    
    /// Creates the Generic Level Set message.
    ///
    /// - parameter level: The Delta change of the Generic Level state.
    public init(level: Int32) {
        self.level = level
        self.transitionTime = nil
        self.delay = nil
    }
    
    /// Creates the Generic Level Set message.
    ///
    /// - parameters:
    ///   - level: The Delta change of the Generic Level state.
    ///   - transitionTime: The time that an element will take to transition
    ///                     to the target state from the present state.
    ///   - delay: Message execution delay in 5 millisecond steps.
    public init(level: Int32, transitionTime: TransitionTime, delay: UInt8) {
        self.level = level
        self.transitionTime = transitionTime
        self.delay = delay
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 5 || parameters.count == 7 else {
            return nil
        }
        level = parameters.read(fromOffset: 0)
        tid = parameters[4]
        if parameters.count == 7 {
            transitionTime = TransitionTime(rawValue: parameters[5])
            delay = parameters[6]
        } else {
            transitionTime = nil
            delay = nil
        }
    }
    
}
