//
//  GenericDeltaSetUnacknowledged.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 23/08/2019.
//

import Foundation

public struct GenericDeltaSetUnacknowledged: GenericMessage, TransactionMessage, TransitionMessage {
    public static let opCode: UInt32 = 0x820A
    
    public var tid: UInt8!
    public var parameters: Data? {
        let data = Data() + delta + tid
        if let transitionTime = transitionTime, let delay = delay {
            return data + transitionTime.rawValue + delay
        } else {
            return data
        }
    }
    
    /// The Delta change of the Generic Level state.
    public let delta: Int32
    
    public let transitionTime: TransitionTime?
    public let delay: UInt8?
    
    /// Creates the Generic Level Set message.
    ///
    /// - parameter delta: The Delta change of the Generic Level state.
    public init(delta: Int32) {
        self.delta = delta
        self.transitionTime = nil
        self.delay = nil
    }
    
    /// Creates the Generic Level Set message.
    ///
    /// - parameters:
    ///   - delta: The Delta change of the Generic Level state.
    ///   - transitionTime: The time that an element will take to transition
    ///                     to the target state from the present state.
    ///   - delay: Message execution delay in 5 millisecond steps.
    public init(delta: Int32, transitionTime: TransitionTime, delay: UInt8) {
        self.delta = delta
        self.transitionTime = transitionTime
        self.delay = delay
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 5 || parameters.count == 7 else {
            return nil
        }
        delta = parameters.read(fromOffset: 0)
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

