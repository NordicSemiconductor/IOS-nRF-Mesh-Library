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

/// Light CTL Set is an acknowledged message used to set the Light CTL Lightness state,
/// Light CTL Temperature state, and the Light CTL Delta UV state of an Element.
///
/// The response to the Light CTL Set message is a ``LightCTLStatus`` message.
public struct LightCTLSet: StaticAcknowledgedMeshMessage, TransactionMessage, TransitionMessage {
    public static let opCode: UInt32 = 0x825E
    public static let responseType: StaticMeshResponse.Type = LightCTLStatus.self
    
    public var tid: UInt8!
    public var parameters: Data? {
        let data = Data() + lightness + temperature + deltaUV + tid
        if let transitionTime = transitionTime, let delay = delay {
            return data + transitionTime.rawValue + delay
        } else {
            return data
        }
    }
    
    /// The target value of the Light CTL Lightness state.
    ///
    /// The Light CTL Lightness state represents the light output of an Element
    /// that is relative to the maximum possible light output of the Element.
    ///
    /// The values for the lightness state are defined in the following table:
    /// - 0x0000 - light is not emitted by the element.
    /// - 0x0001 - 0xFFFE - The light lightness of a light emitted by the element.
    /// - 0xFFFF - the highest lightness of a light emitted by the element.
    public let lightness: UInt16
    /// The target value of the Light CTL Temperature state.
    ///
    /// The Light CTL Temperature state determines the color temperature of
    /// tunable white light emitted by an Element.
    ///
    /// Valid values are in range 0x0320-0x4320 (800-20000K).
    public let temperature: UInt16
    /// The 16-bit signed value representing the Delta UV of a tunable white
    /// light. A value of 0x0000 represents Delta UV = 0.
    public let deltaUV: Int16
    
    public var transitionTime: TransitionTime?
    public var delay: UInt8?
    
    /// Creates the Light CTL Set message.
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
    /// The Light CTL Delta UV state determines the distance from the Black Body
    /// curve. The color temperature of all on the black body locus (curve).
    /// This is a 16-bit signed integer representation of a -1 to +1 scale using
    /// the formula:
    ///
    /// Represented Delta UV = ``LightCTLSet/deltaUV`` / 32768
    ///
    /// - parameters:
    ///   - lightness: The target value of the Light CTL Lightness state.
    ///   - temperature: The target value of the Light CTL Temperature state.
    ///   - deltaUV: The target value of the Light CTL Delta UV state.
    public init(lightness: UInt16, temperature: UInt16, deltaUV: Int16) {
        self.lightness = lightness
        self.temperature = max(0x0320, min(temperature, 0x4E20))
        self.deltaUV = deltaUV
        self.transitionTime = nil
        self.delay = nil
    }
    
    /// Creates the Light CTL Set message.
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
    /// The Light CTL Delta UV state determines the distance from the Black Body
    /// curve. The color temperature of all on the black body locus (curve).
    /// This is a 16-bit signed integer representation of a -1 to +1 scale using
    /// the formula:
    ///
    /// Represented Delta UV = ``LightCTLSet/deltaUV`` / 32768
    ///
    /// - parameters:
    ///   - lightness: The target value of the Light CTL Lightness state.
    ///   - temperature: The target value of the Light CTL Temperature state.
    ///   - deltaUV: The target value of the Light CTL Delta UV state.
    ///   - transitionTime: The time that an element will take to transition
    ///                     to the target state from the present state.
    ///   - delay: Message execution delay in 5 millisecond steps.
    public init(lightness: UInt16, temperature: UInt16, deltaUV: Int16,
                transitionTime: TransitionTime, delay: UInt8) {
        self.lightness = lightness
        self.temperature = max(0x0320, min(temperature, 0x4E20))
        self.deltaUV = deltaUV
        self.transitionTime = transitionTime
        self.delay = delay
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 7 || parameters.count == 9 else { return nil }
        lightness = parameters.read()
        temperature = parameters.read(fromOffset: 2)
        deltaUV = parameters.read(fromOffset: 4)
        tid = parameters[6]
        if parameters.count == 9 {
            transitionTime = TransitionTime(rawValue: parameters[7])
            delay = parameters[8]
        } else {
            transitionTime = nil
            delay = nil
        }
    }
    
}
