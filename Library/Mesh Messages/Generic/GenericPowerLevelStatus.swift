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

public struct GenericPowerLevelStatus: StaticMeshResponse, TransitionStatusMessage {
    public static var opCode: UInt32 = 0x8218
    
    public var parameters: Data? {
        let data = Data() + power
        if let targetPower = targetPower, let remainingTime = remainingTime {
            return data + targetPower + remainingTime.rawValue
        } else {
            return data
        }
    }
    
    /// The present value of the Generic Power Actual state.
    public let power: UInt16
    /// The target value of the Generic Power Actual state.
    public let targetPower: UInt16?
    
    public let remainingTime: TransitionTime?
    
    /// Creates the Generic Power Level Status message.
    ///
    /// - parameter power: The present value of the Generic Power Actual state.
    public init(power: UInt16) {
        self.power = power
        self.targetPower = nil
        self.remainingTime = nil
    }
    
    /// Creates the Generic Power Level Status message.
    ///
    /// - parameters:
    ///   - power: The present value of the Generic Power Actual state.
    ///   - targetPower: The target value of the Generic Power Actual state.
    ///   - remainingTime: The time that an element will take to transition
    ///                    to the target state from the present state.
    public init(power: UInt16, targetPower: UInt16, remainingTime: TransitionTime) {
        self.power = power
        self.targetPower = targetPower
        self.remainingTime = remainingTime
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 2 || parameters.count == 5 else {
            return nil
        }
        power = parameters.read(fromOffset: 0)
        if parameters.count == 5 {
            targetPower = parameters.read(fromOffset: 2)
            remainingTime = TransitionTime(rawValue: parameters[4])
        } else {
            targetPower = nil
            remainingTime = nil
        }
    }
}

