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

public struct LightHSLRangeSetUnacknowledged: StaticUnacknowledgedMeshMessage {
    public static let opCode: UInt32 = 0x8282
    
    public var parameters: Data? {
        return Data() + minHue + maxHue + minSaturation + maxSaturation
    }
    
    /// The value of the Hue Range Min field of the Light HSL Range state.
    public let minHue: UInt16
    /// The value of the Hue Range Max field of the Light HSL Range state.
    public let maxHue: UInt16
    /// The value of the Saturation Range Min field of the Light HSL Range state.
    public let minSaturation: UInt16
    /// The value of the Saturation Range Max field of the Light HSL Range state.
    public let maxSaturation: UInt16
    
    /// The value of the Hue Range field of the Light HSL Range state.
    public var hueRange: ClosedRange<UInt16> {
        return minHue...maxHue
    }
    /// The value of the Saturation Range field of the Light HSL Range state.
    public var saturationRange: ClosedRange<UInt16> {
        return minSaturation...maxSaturation
    }
    
    /// Creates the Light HSL Range Set Unacknowledged message.
    ///
    /// - parameter hueRange: The value of the Light HSL Hue Range state.
    /// - parameter saturationRange: The value of the Light HSL Saturation Range state.
    public init(hueRange: ClosedRange<UInt16>, saturationRange: ClosedRange<UInt16>) {
        self.minHue = hueRange.lowerBound
        self.maxHue = hueRange.upperBound
        self.minSaturation = saturationRange.lowerBound
        self.maxSaturation = saturationRange.upperBound
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 8 else {
            return nil
        }
        minHue = parameters.read()
        maxHue = parameters.read(fromOffset: 2)
        minSaturation = parameters.read(fromOffset: 4)
        maxSaturation = parameters.read(fromOffset: 6)
    }
    
}
