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

public struct GenericPowerLevelSetUnacknowledged: StaticUnacknowledgedMeshMessage, TransactionMessage, TransitionMessage {
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

