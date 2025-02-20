/*
* Copyright (c) 2021, Nordic Semiconductor
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

/// The Light LC Light OnOff Status is an unacknowledged message used to report the
/// Light LC State Machine Light OnOff state of an Element.
public struct LightLCLightOnOffStatus: StaticMeshResponse, TransitionStatusMessage {
    public static var opCode: UInt32 = 0x829C
    
    public var parameters: Data? {
        let data = Data([isOn ? 0x01 : 0x00])
        if let targetState = targetState, let remainingTime = remainingTime {
            return data + UInt8(targetState ? 0x01 : 0x00) + remainingTime.rawValue
        } else {
            return data
        }
    }
    
    /// The present value of the Light LC Light OnOff state.
    ///
    /// If enabled, the Light LC State Machine state is equal to Off or equal to Standby.
    public let isOn: Bool
    /// The target value of the Light LC Light OnOff state.
    public let targetState: Bool?
    
    public let remainingTime: TransitionTime?
    
    /// Creates the Light LC Light OnOff Status message.
    ///
    /// - parameter isOn: The present value of the Light LC Light OnOff state.
    public init(_ isOn: Bool) {
        self.isOn = isOn
        self.targetState = nil
        self.remainingTime = nil
    }
    
    /// Creates the Light LC Light OnOff Status message.
    ///
    /// - parameters:
    ///   - isOn: The present value of the Light LC Light OnOff state.
    ///   - targetState: The target value of the Light LC Light OnOff state.
    ///   - remainingTime: The time that an element will take to transition
    ///                    to the target state from the present state.
    public init(_ isOn: Bool, targetState: Bool, remainingTime: TransitionTime) {
        self.isOn = isOn
        self.targetState = targetState
        self.remainingTime = remainingTime
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 1 || parameters.count == 3 else {
            return nil
        }
        isOn = parameters[0] == 0x01
        if parameters.count == 3 {
            targetState = parameters[1] == 0x01
            remainingTime = TransitionTime(rawValue: parameters[2])
        } else {
            targetState = nil
            remainingTime = nil
        }
    }
}
