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

public struct GenericOnOffSetUnacknowledged: StaticUnacknowledgedMeshMessage, TransactionMessage, TransitionMessage {
    public static let opCode: UInt32 = 0x8203
    
    public var tid: UInt8!
    public var parameters: Data? {
        let data = Data([isOn ? 0x01 : 0x00, tid])
        if let transitionTime = transitionTime, let delay = delay {
            return data + transitionTime.rawValue + delay
        } else {
            return data
        }
    }
    
    /// The new state of Generic OnOff Server.
    public let isOn: Bool
    
    public let transitionTime: TransitionTime?
    public let delay: UInt8?
    
    /// Creates the Generic OnOff Set Unacknowledged message.
    ///
    /// - parameter isOn: The target value of the Generic OnOff state.
    public init(_ isOn: Bool) {
        self.isOn = isOn
        self.transitionTime = nil
        self.delay = nil
    }
    
    /// Creates the Generic OnOff Set Unacknowledged message.
    ///
    /// - parameters:
    ///   - isOn: The target value of the Generic OnOff state.
    ///   - transitionTime: The time that an element will take to transition
    ///                     to the target state from the present state.
    ///   - delay: Message execution delay in 5 millisecond steps.
    public init(_ isOn: Bool, transitionTime: TransitionTime, delay: UInt8) {
        self.isOn = isOn
        self.transitionTime = transitionTime
        self.delay = delay
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 2 || parameters.count == 4 else {
            return nil
        }
        isOn = parameters[0] == 0x01
        tid = parameters[1]
        if parameters.count == 4 {
            transitionTime = TransitionTime(rawValue: parameters[2])
            delay = parameters[3]
        } else {
            transitionTime = nil
            delay = nil
        }
    }
    
}
