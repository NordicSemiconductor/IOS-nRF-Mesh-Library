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
public struct LightLightnessSet: StaticAcknowledgedMeshMessage, TransactionMessage, TransitionMessage {
    public static var opCode: UInt32 = 0x824C
    public static var responseType: StaticMeshResponse.Type = LightLightnessStatus.self
    
    public var tid: UInt8!    
    public var parameters: Data? {
        let data = Data() + lightness + tid
        if let transitionTime = transitionTime, let delay = delay {
            return data + transitionTime.rawValue + delay
        } else {
            return data
        }
    }
    
    /// The target value of the Light Lightness Actual state.
    public let lightness: UInt16
    
    public let transitionTime: TransitionTime?
    public let delay: UInt8?
    
    /// Creates the Light Lightness Set message.
    ///
    /// The values for the state are defined in the following table:
    /// - 0x0000 - light is not emitted by the element.
    /// - 0x0001 - 0xFFFE - The light lightness of a light emitted by the element.
    /// - 0xFFFF - the highest lightness of a light emitted by the element.
    ///
    /// - parameter lightness: The target value of the Light Lightness Actual state.
    public init(lightness: UInt16) {
        self.lightness = lightness
        self.transitionTime = nil
        self.delay = nil
    }
    
    /// Creates the Light Lightness Set message.
    ///
    /// The values for the state are defined in the following table:
    /// - 0x0000 - light is not emitted by the element.
    /// - 0x0001 - 0xFFFE - The light lightness of a light emitted by the element.
    /// - 0xFFFF - the highest lightness of a light emitted by the element.
    ///
    /// - parameters:
    ///   - lightness: The target value of the Light Lightness Actual state.
    ///   - transitionTime: The time that an element will take to transition
    ///                     to the target state from the present state.
    ///   - delay: Message execution delay in 5 millisecond steps.
    public init(lightness: UInt16, transitionTime: TransitionTime, delay: UInt8) {
        self.lightness = lightness
        self.transitionTime = transitionTime
        self.delay = delay
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 3 || parameters.count == 5 else {
            return nil
        }
        lightness = parameters.read()
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
