//
//  TransitionTime.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 22/08/2019.
//

import Foundation

public struct TransitionTime {
    /// Transition Number of Steps, 6-bit value.
    ///
    /// Value 0 indicates an immediate transition.
    ///
    /// Value 0x3F means that the value is unknown. The state cannot be
    /// set to this value, but an element may report an unknown value if
    /// a transition is higher than 0x3E or not determined.
    public let steps: UInt8
    /// The step resolution.
    public let stepResolution: StepResolution
    
    /// The transition time in milliseconds.
    public var milliseconds: Int {
        return stepResolution.toPeriod(steps: steps & 0x3F)
    }
    /// The transition time as `TimeInterval` in seconds.
    public var interval: TimeInterval {
        return TimeInterval(milliseconds) / 1000.0
    }
    
    internal var rawValue: UInt8 {
        return (steps & 0x3F) | (stepResolution.rawValue << 6)
    }
    
    /// Creates the Transition Time object.
    ///
    /// Only values of 0x00 through 0x3E shall be used to specify the value
    /// of the Transition Number of Steps field.
    ///
    /// - parameter steps: Transition Number of Steps, valid values are in
    ///                    range 0...62. Value 63 means that the value is
    ///                    unknown and the state cannot be set to this value.
    /// - parameter stepResolution: The step resolution.
    public init(steps: UInt8, stepResolution: StepResolution) {
        self.steps = min(steps, 0x3E)
        self.stepResolution = stepResolution
    }
    
    /// Creates the Transition Time object for an unknown time.
    public init() {
        self.steps = 0x3F
        self.stepResolution = .hundredsOfMilliseconds
    }
    
    internal init(rawValue: UInt8) {
        self.steps = rawValue & 0x3F
        self.stepResolution = StepResolution(rawValue: rawValue >> 6)!
    }
}

public extension TransitionTime {
    
    /// Returns whether the transition time is known.
    var isKnown: Bool {
        return steps < 0x3F
    }
    
}

extension TransitionTime: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        guard isKnown else {
            return "Unknown"
        }
        if steps == 0 {
            return "Immediate"
        }
        
        let value = Int(steps)
        
        switch stepResolution {
        case .hundredsOfMilliseconds where steps < 10:
            return "\(value * 100) ms"
        case .hundredsOfMilliseconds where steps == 10:
            return "1 sec"
        case .hundredsOfMilliseconds:
            return "\(value / 10).\(value % 10) sec"
            
        case .seconds where steps < 60:
            return "\(value) sec"
        case .seconds where steps == 60:
            return "1 min"
        case .seconds:
            return "1 min \(value - 60) sec"
            
        case .tensOfSeconds where steps < 6:
            return "\(value * 10) sec"
        case .tensOfSeconds where steps % 6 == 0:
            return "\(value / 6) min"
        case .tensOfSeconds:
            return "\(value / 6) min \(value % 6 * 10) sec"
            
        case .tensOfMinutes where steps < 6:
            return "\(value * 10) min"
        case .tensOfMinutes where steps % 6 == 0:
            return "\(value / 6) h"
        case .tensOfMinutes:
            return "\(value / 6) h \(value % 6 * 10) min"
        }
    }
    
}
