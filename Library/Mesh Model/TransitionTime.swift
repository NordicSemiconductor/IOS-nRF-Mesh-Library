/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

/// This structure represents a time needed to transition from one state to another,
/// for example dimming a light.
///
/// Internally, it uses steps and step resolution. Thanks to that only some time
/// intervals are possible. Use ``TransitionTime/interval`` to get exact time
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
    ///
    /// `nil` value represents an unknown time.
    public var milliseconds: Int? {
        guard steps != 0x3F else {
            return nil
        }
        return stepResolution.toMilliseconds(steps: steps & 0x3F)
    }
    /// The transition time as `TimeInterval` in seconds.
    ///
    /// `nil` value represents an unknown time.
    public var interval: TimeInterval? {
        guard let milliseconds = milliseconds else {
            return nil
        }
        return TimeInterval(milliseconds) / 1000.0
    }
    
    /// The raw representation of the transition in a mesh message.
    public var rawValue: UInt8 {
        return (steps & 0x3F) | (stepResolution.rawValue << 6)
    }
    
    /// Creates the Transition Time object.
    ///
    /// Only values of 0x00 through 0x3E shall be used to specify the value
    /// of the Transition Number of Steps field.
    ///
    /// - note: Use ``TransitionTime/init()`` to create a Transition Time
    ///         representing an unknown time.
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
    
    /// Creates the Transition Time object for the `TimeInterval`.
    ///
    /// - note: Mind, that the transition time will be converted to steps
    ///         and step resolution using rounding. Check implementation
    ///         for details.
    ///
    /// - parameter interval: The transition time in seconds.
    public init(_ interval: TimeInterval) {
        switch interval {
        case let interval where interval <= 0:
            steps = 0
            stepResolution = .hundredsOfMilliseconds
        case let interval where interval <= 62 * 0.100:
            steps = UInt8(interval * 10)
            stepResolution = .hundredsOfMilliseconds
        case let interval where interval <= 62 * 1.0:
            steps = UInt8(interval)
            stepResolution = .seconds
        case let interval where interval <= 62 * 10.0:
            steps = UInt8(interval / 10.0)
            stepResolution = .tensOfSeconds
        case let interval where interval <= 62 * 10 * 60.0:
            steps = UInt8(interval / (10 * 60.0))
            stepResolution = .tensOfMinutes
        default:
            steps = 0x3E
            stepResolution = .tensOfMinutes
        }
    }
    
    public init(rawValue: UInt8) {
        self.steps = rawValue & 0x3F
        self.stepResolution = StepResolution(rawValue: rawValue >> 6)!
    }
}

public extension TransitionTime {
    
    /// Transition is immediate.
    static let immediate = TransitionTime(steps: 0, stepResolution: .hundredsOfMilliseconds)
    /// Unknown transition time.
    ///
    /// This cannot be used as default transition time.
    static let unknown = TransitionTime()
    
    /// Returns whether the transition time is known.
    var isKnown: Bool {
        return steps < 0x3F
    }
    
    /// Whether the transition is immediate.
    var isImmediate: Bool {
        return steps == 0
    }
    
}

public extension Optional where Wrapped == TransitionTime {
    
    /// Returns this Transition Time value, if it's known, or
    /// the default value. If default value is `nil`, instantaneous
    /// transition is returned.
    ///
    /// - parameter defaultTransitionTime: The optional default value
    ///                                    of the transition time.
    func or(_ defaultTransitionTime: TransitionTime?) -> TransitionTime {
        switch self {
        case .some(let transitionTime) where transitionTime.isKnown:
            return transitionTime
            
        default:
            return defaultTransitionTime ?? .immediate
        }
    }
    
}

extension TransitionTime: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        guard isKnown else {
            return "Unknown"
        }
        if isImmediate {
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
