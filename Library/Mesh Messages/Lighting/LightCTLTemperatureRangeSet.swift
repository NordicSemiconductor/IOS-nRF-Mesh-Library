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

/// Light CTL Temperature Range Set is an acknowledged message used to set the
/// Light CTL Temperature Range state of an Element.
///
/// The Light CTL Temperature Range state determines the minimum and maximum
/// color temperatures of tunable white light an Element is capable of emitting.
///
/// The response to the Light CTL Temperature Range Set message is a ``LightCTLTemperatureRangeStatus`` message.
public struct LightCTLTemperatureRangeSet: StaticAcknowledgedMeshMessage {
    public static let opCode: UInt32 = 0x826B
    public static let responseType: StaticMeshResponse.Type = LightCTLTemperatureRangeStatus.self
    
    public var parameters: Data? {
        return Data() + min + max
    }
    
    /// The value of the Temperature Range Min field of the Light CTL Temperature
    /// Range state.
    public let min: UInt16
    /// The value of the Temperature Range Max field of the Light CTL Temperature
    /// Range state.
    public let max: UInt16
    /// The value of the Light CTL Temperature Range state.
    public var range: ClosedRange<UInt16> {
        return min...max
    }
    
    /// Creates the Light CTL Temperature Range Set message.
    ///
    /// - parameter range: The value of the Light CTL Temperature Range state.
    public init(_ range: ClosedRange<UInt16>) {
        self.min = range.lowerBound
        self.max = range.upperBound
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 4 else {
            return nil
        }
        min = parameters.read()
        max = parameters.read(fromOffset: 2)
    }
    
}
