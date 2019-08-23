//
//  GenericLevelStatus.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 23/08/2019.
//

import Foundation

public struct GenericLevelStatus: StaticMeshMessage, TransitionStatusMessage {
    public static var opCode: UInt32 = 0x8208
    
    public var parameters: Data? {
        let data = Data() + level
        if let targetLevel = targetLevel, let remainingTime = remainingTime {
            return data + targetLevel + remainingTime.rawValue
        } else {
            return data
        }
    }
    
    /// The present value of the Generic Level state.
    public let level: Int16
    /// The target value of the Generic Level state.
    public let targetLevel: Int16?
    
    public let remainingTime: TransitionTime?
    
    /// Creates the Generic Level Status message.
    ///
    /// - parameter level: The target value of the Generic Level state.
    public init(level: Int16) {
        self.level = level
        self.targetLevel = nil
        self.remainingTime = nil
    }
    
    /// Creates the Generic Level Status message.
    ///
    /// - parameters:
    ///   - level: The target value of the Generic Level state.
    ///   - targetLevel: The target value of the Generic Level state.
    ///   - remainingTime: The time that an element will take to transition
    ///                    to the target state from the present state.
    public init(level: Int16, targetLevel: Int16, remainingTime: TransitionTime) {
        self.level = level
        self.targetLevel = targetLevel
        self.remainingTime = remainingTime
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 2 || parameters.count == 5 else {
            return nil
        }
        level = parameters.read(fromOffset: 0)
        if parameters.count == 5 {
            targetLevel = parameters.read(fromOffset: 2)
            remainingTime = TransitionTime(rawValue: parameters[4])
        } else {
            targetLevel = nil
            remainingTime = nil
        }
    }
}
