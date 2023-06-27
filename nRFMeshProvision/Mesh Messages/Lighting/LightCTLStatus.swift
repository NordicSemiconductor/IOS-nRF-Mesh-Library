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

public struct LightCTLStatus: StaticMeshResponse, TransitionStatusMessage {
    public static var opCode: UInt32 = 0x8260
    
    public var parameters: Data? {
        let data = Data() + lightness + temperature
        if let targetLightness = targetLightness,
           let targetTemperature = targetTemperature,
           let remainingTime = remainingTime {
            return data + targetLightness + targetTemperature + remainingTime.rawValue
        } else {
            return data
        }
    }
    
    /// The present value of the Light CTL Lightness state.
    public let lightness: UInt16
    /// The present value of the Light CTL Temperature state.
    public let temperature: UInt16
    /// The target value of the Light CTL Lightness state.
    public let targetLightness: UInt16?
    /// The target value of the Light CTL Temperature state.
    public let targetTemperature: UInt16?
    
    public let remainingTime: TransitionTime?
    
    /// Creates the Light CTL Status message.
    ///
    /// The values for the lightness state are defined in the following table:
    /// - 0x0000 - light is not emitted by the element.
    /// - 0x0001 - 0xFFFE - The light lightness of a light emitted by the element.
    /// - 0xFFFF - the highest lightness of a light emitted by the element.
    ///
    /// The temperature parameter is color temperature of white light in Kelvin.
    /// The vales for this state are defined in the following table:
    /// - 0x0320 - 0x4E20 - color temperature of white light in Kelvin
    /// - All other values are prohibited and will be rounded to the nearest
    ///   valid value.
    ///
    /// - parameters:
    ///   - lightness: The present value of the Light CTL Lightness state.
    ///   - temperature: The present value of the Light CTL Temperature state.
    public init(lightness: UInt16, temperature: UInt16) {
        self.lightness = lightness
        self.temperature = max(0x0320, min(temperature, 0x4E20))
        self.targetLightness = nil
        self.targetTemperature = nil
        self.remainingTime = nil
    }
    
    /// Creates the Light CTL Status message.
    ///
    /// The values for the lightness state are defined in the following table:
    /// - 0x0000 - light is not emitted by the element.
    /// - 0x0001 - 0xFFFE - The light lightness of a light emitted by the element.
    /// - 0xFFFF - the highest lightness of a light emitted by the element.
    ///
    /// The temperature parameter is color temperature of white light in Kelvin.
    /// The vales for this state are defined in the following table:
    /// - 0x0320 - 0x4E20 - color temperature of white light in Kelvin
    /// - All other values are prohibited and will be rounded to the nearest
    ///   valid value.
    ///
    /// - parameters:
    ///   - lightness: The present value of the Light CTL Lightness state.
    ///   - temperature: The present value of the Light CTL Temperature state.
    ///   - targetLightness: The target value of the Light CTL Lightness state.
    ///   - targetTemperature: The target value of the Light CTL Temperature state.
    ///   - remainingTime: The time that an element will take to transition
    ///                    to the target state from the present state.
    public init(lightness: UInt16, temperature: UInt16,
                targetLightness: UInt16, targetTemperature: UInt16,
                remainingTime: TransitionTime) {
        self.lightness = lightness
        self.temperature = max(0x0320, min(temperature, 0x4E20))
        self.targetLightness = targetLightness
        self.targetTemperature = targetTemperature
        self.remainingTime = remainingTime
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 4 || parameters.count == 9 else {
            return nil
        }
        lightness = parameters.read()
        temperature = parameters.read(fromOffset: 2)
        if parameters.count == 9 {
            targetLightness = parameters.read(fromOffset: 4)
            targetTemperature = parameters.read(fromOffset: 6)
            remainingTime = TransitionTime(rawValue: parameters[8])
        } else {
            targetLightness = nil
            targetTemperature = nil
            remainingTime = nil
        }
    }
}
