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

public struct LightCTLDefaultSet: StaticAcknowledgedMeshMessage {
    public static let opCode: UInt32 = 0x8269
    public static let responseType: StaticMeshResponse.Type = LightCTLDefaultStatus.self
    
    public var parameters: Data? {
        return Data() + lightness + temperature + deltaUV
    }
    
    /// The value of the Light CTL Lightness state.
    public let lightness: UInt16
    /// The value of the Light CTL Temperature state.
    ///
    /// Valid values are in range 0x0320-0x4320 (800-20000K).
    public let temperature: UInt16
    /// The 16-bit signed value representing the Delta UV of a tunable white
    /// light. A value of 0x0000 represents Delta UV = 0.
    public let deltaUV: Int16
    
    /// Creates the Light CTL Default Set message.
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
    /// Represented Delta UV = ``LightCTLDefaultSet/deltaUV`` / 32768
    ///
    /// - parameters:
    ///   - lightness: The target value of the Light CTL Lightness state.
    ///   - temperature: The target value of the Light CTL Temperature state.
    ///   - deltaUV: The target value of the Light CTL Delta UV state.
    public init(lightness: UInt16, temperature: UInt16, deltaUV: Int16) {
        self.lightness = lightness
        self.temperature = max(0x0320, min(temperature, 0x4E20))
        self.deltaUV = deltaUV
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 6 else {
            return nil
        }
        lightness = parameters.read()
        temperature = parameters.read(fromOffset: 2)
        deltaUV = parameters.read(fromOffset: 4)
    }
    
}
