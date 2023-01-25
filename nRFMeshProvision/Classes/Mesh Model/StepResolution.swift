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

/// The Step Resolution field enumerates the resolution of the Number of Steps field
/// in ``TransitionTime`` or ``Publish/Period-swift.struct``.
public enum StepResolution: UInt8 {
    /// The Step Resolution is 100 milliseconds.
    case hundredsOfMilliseconds = 0b00
    /// The Step Resolution is 1 second.
    case seconds                = 0b01
    /// The Step Resolution is 10 seconds.
    case tensOfSeconds          = 0b10
    /// The Step Resolution is 10 minutes.
    case tensOfMinutes          = 0b11
}

internal extension StepResolution {
    
    init?(from resolution: Int) {
        switch resolution {
        case 100:
            self = .hundredsOfMilliseconds
        case 1000:
            self = .seconds
        case 10000:
            self = .tensOfSeconds
        case 600000:
            self = .tensOfMinutes
        default:
            return nil
        }
    }
    
    /// Converts the steps to milliseconds using the step resolution.
    func toMilliseconds(steps: UInt8) -> Int {
        switch self {
        case .hundredsOfMilliseconds:
            return Int(steps) * 100
        case .seconds:
            return Int(steps) * 1000
        case .tensOfSeconds:
            return Int(steps) * 10000
        case .tensOfMinutes:
            return Int(steps) * 600000
        }
    }
    
}

extension StepResolution: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .hundredsOfMilliseconds:
            return "100 milliseconds"
        case .seconds:
            return "1 second"
        case .tensOfSeconds:
            return "10 seconds"
        case .tensOfMinutes:
            return "10 minutes"
        }
    }
    
}
