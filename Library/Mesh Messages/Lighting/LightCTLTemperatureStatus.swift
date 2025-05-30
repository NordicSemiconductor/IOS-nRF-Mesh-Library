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

/// Light CTL Temperature Status is an unacknowledged message used to report
/// the Light CTL Temperature and Light CTL Delta UV state of an Element.
///
/// The Light CTL Temperature state determines the color temperature of
/// tunable white light emitted by an Element, in Kelvin. 
public struct LightCTLTemperatureStatus: StaticMeshResponse, TransitionStatusMessage {
    public static var opCode: UInt32 = 0x8266
    
    public var parameters: Data? {
        let data = Data() + temperature + deltaUV
        if let targetTemperature = targetTemperature,
           let targetDeltaUV = targetDeltaUV,
           let remainingTime = remainingTime {
            return data + targetTemperature + targetDeltaUV +  remainingTime.rawValue
        } else {
            return data
        }
    }
    
    /// The present value of the Light CTL Temperature state.
    public let temperature: UInt16
    /// The present value of the Light CTL Delta UV state.
    public let deltaUV: Int16
    /// The target value of the Light CTL Temperature state.
    public let targetTemperature: UInt16?
    /// The target value of the Light CTL Delta UV state.
    public let targetDeltaUV: Int16?
    
    public let remainingTime: TransitionTime?
    
    /// Creates the Light CTL Temperature Status message.
    ///
    /// The temperature parameter is color temperature of white light in Kelvin.
    /// The vales for this state are defined in the following table:
    /// - 0x0320 - 0x4E20 - color temperature of white light in Kelvin
    /// - All other values are prohibited and will be rounded to the nearest
    ///   valid value.
    ///
    /// The Light CTL Delta UV state determines the distance from the Black Body
    /// curve. The color temperature of all on the black body locus (curve).
    /// This is a 16-bit signed integer representation of a -1 to +1 scale using
    /// the formula:
    ///
    /// Represented Delta UV = ``LightCTLTemperatureStatus/deltaUV`` / 32768
    ///
    /// - parameters:
    ///   - temperature: The present value of the Light CTL Temperature state.
    ///   - deltaUV: The present value of the Light CTL Delta UV state.
    public init(temperature: UInt16, deltaUV: Int16) {
        self.temperature = max(0x0320, min(temperature, 0x4E20))
        self.deltaUV = deltaUV
        self.targetTemperature = nil
        self.targetDeltaUV = nil
        self.remainingTime = nil
    }
    
    /// Creates the Light CTL Temperature Status message.
    ///
    /// The temperature parameter is color temperature of white light in Kelvin.
    /// The vales for this state are defined in the following table:
    /// - 0x0320 - 0x4E20 - color temperature of white light in Kelvin
    /// - All other values are prohibited and will be rounded to the nearest
    ///   valid value.
    ///
    /// The Light CTL Delta UV state determines the distance from the Black Body
    /// curve. The color temperature of all on the black body locus (curve).
    /// This is a 16-bit signed integer representation of a -1 to +1 scale using
    /// the formula:
    ///
    /// Represented Delta UV = ``LightCTLTemperatureStatus/deltaUV`` / 32768
    ///
    /// - parameters:
    ///   - temperature: The present value of the Light CTL Temperature state.
    ///   - deltaUV: The present value of the Light CTL Delta UV state.
    ///   - targetTemperature: The target value of the Light CTL Temperature state.
    ///   - targetDeltaUV: The target value of the Light CTL Delta UV state.
    ///   - remainingTime: The time that an element will take to transition
    ///                    to the target state from the present state.
    public init(temperature: UInt16, deltaUV: Int16,
                targetTemperature: UInt16, targetDeltaUV: Int16,
                remainingTime: TransitionTime) {
        self.temperature = max(0x0320, min(temperature, 0x4E20))
        self.deltaUV = deltaUV
        self.targetTemperature = max(0x0320, min(targetTemperature, 0x4E20))
        self.targetDeltaUV = targetDeltaUV
        self.remainingTime = remainingTime
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 4 || parameters.count == 9 else {
            return nil
        }
        temperature = parameters.read()
        deltaUV = parameters.read(fromOffset: 2)
        if parameters.count == 9 {
            targetTemperature = parameters.read(fromOffset: 4)
            targetDeltaUV = parameters.read(fromOffset: 6)
            remainingTime = TransitionTime(rawValue: parameters[8])
        } else {
            targetTemperature = nil
            targetDeltaUV = nil
            remainingTime = nil
        }
    }
}
