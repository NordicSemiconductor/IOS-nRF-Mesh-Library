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

public struct LightHSLHueStatus: StaticMeshResponse, TransitionStatusMessage {
    public static var opCode: UInt32 = 0x8271
    
    public var parameters: Data? {
        let data = Data() + hue
        if let targetHue = targetHue, let remainingTime = remainingTime {
            return data + targetHue + remainingTime.rawValue
        } else {
            return data
        }
    }
    
    /// The present value of the Light HSL Hue state.
    public let hue: UInt16
    /// The target value of the Light HSL Hue state.
    public let targetHue: UInt16?
    
    public let remainingTime: TransitionTime?
    
    /// Creates the Light HSL Hue Status message.
    ///
    /// Hue is representing by 16-bit unsigned integer of a 0-360 degree scale
    /// using the formula:
    ///
    /// H (degrees) = 360 * hue / 65536
    ///
    /// - parameters:
    ///   - hue: The present value of the Light HSL Hue state.
    public init(hue: UInt16) {
        self.hue = hue
        self.targetHue = nil
        self.remainingTime = nil
    }
    
    /// Creates the Light HSL Hue Status message.
    ///
    /// Hue is representing by 16-bit unsigned integer of a 0-360 degree scale
    /// using the formula:
    ///
    /// H (degrees) = 360 * hue / 65536
    ///
    /// - parameters:
    ///   - hue: The present value of the Light HSL Hue state.
    ///   - targetHue: The target value of the Light HSL Hue state.
    ///   - remainingTime: The time that an element will take to transition
    ///                    to the target state from the present state.
    public init(hue: UInt16, targetHue: UInt16,
                remainingTime: TransitionTime) {
        self.hue = hue
        self.targetHue = targetHue
        self.remainingTime = remainingTime
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 2 || parameters.count == 5 else { return nil }
        hue = parameters.read()
        if parameters.count == 5 {
            targetHue = parameters.read(fromOffset: 2)
            remainingTime = TransitionTime(rawValue: parameters[4])
        } else {
            targetHue = nil
            remainingTime = nil
        }
    }
    
}
