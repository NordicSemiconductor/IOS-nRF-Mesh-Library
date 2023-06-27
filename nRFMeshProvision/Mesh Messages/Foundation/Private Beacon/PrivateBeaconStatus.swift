/*
* Copyright (c) 2023, Nordic Semiconductor
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

/// A Private Beacon Status message is an unacknowledged message used to report
/// the current Private Beacon state and Random Update Interval Steps state of a Node.
public struct PrivateBeaconStatus: ConfigResponse {
    public static let opCode: UInt32 = 0x8062
    
    /// Current value of the Private Beacon state.
    public let enabled: Bool
    /// Current value of the Random Update Interval Steps state as raw value.
    public let steps: UInt8
    /// Current value of the Random Update Interval Steps state.
    public var interval: RandomUpdateIntervalSteps {
        switch steps {
        case 0:
            return .everyTime
        default:
            return .interval(n: steps)
        }
    }
    
    public var parameters: Data? {
        return Data() + enabled + steps
    }
    
    /// Creates a Private Beacon Status message with the Random Update Inteval State
    /// set to ``RandomUpdateIntervalSteps/everyTime``.
    public init(enabled: Bool) {
        self.enabled = enabled
        self.steps = 0
    }
    
    /// Creates a Private Beacon Status message with the Random Update Inteval State
    /// set to ``RandomUpdateIntervalSteps/interval(n:)`` with given interval.
    ///
    /// The interval will be rounded to multiply of 10 seconds.
    ///
    /// The maximum value is 42 minutes.
    public init(enabled: Bool, interval: TimeInterval) {
        self.enabled = enabled
        // Maximum value is 42 minutes = 2560 seconds.
        // Minimum value is 10 seconds.
        self.steps = UInt8(min(2560.0, max(interval, 10.0)) / 10.0)
    }
    
    /// Creates a Private Beacon Status message with the Random Update Inteval State
    /// set to the given value.
    ///
    /// The interval is given in 10 secons steps. If set to 0, Random Update Interval
    /// State will be set to ``RandomUpdateIntervalSteps/everyTime``.
    ///
    /// The maximum value is 0xFF, which indicates 42 minutes.
    public init(enabled: Bool, steps: UInt8) {
        self.enabled = enabled
        self.steps = steps
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 2,
              parameters[0] <= 1 else {
            return nil
        }
        self.init(enabled: parameters[0] == 1, steps: parameters[1])
    }
}
