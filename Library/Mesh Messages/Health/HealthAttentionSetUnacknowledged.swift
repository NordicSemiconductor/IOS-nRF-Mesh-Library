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

/// A Health Attention Set Unacknowledged is an unacknowledged message used to set the current
/// Attention Timer state of an Element.
///
/// The Attention Timer is intended to allow an Element to attract human attention and, among others,
/// is used during provisioning.
///
/// When the Attention Timer state is on, the value determines how long (in seconds) the Element shall
/// remain attracting human’s attention. The Element does that by behaving in a human-recognizable
/// way (e.g., a lamp flashes, a motor makes noise, an LED blinks). The exact behavior is implementation
/// specific and depends on the type of device.
public struct HealthAttentionSetUnacknowledged: StaticUnacknowledgedMeshMessage {
    public static let opCode: UInt32 = 0x8006
    
    public var parameters: Data? {
        return Data([attentionTimer])
    }
    
    /// The duration of the Attention Timer, in seconds.
    ///
    /// Set to 0 if the Timer is off, or not supported.
    public let attentionTimer: UInt8
    
    /// Returns whether the Attention Timer is on, or off.
    public var isOn: Bool {
        return attentionTimer != 0
    }
    
    /// Creates the Health Attention Set Unacknowledged message.
    ///
    /// - parameter duration: The duration of the Attention Timer, in seconds.
    ///             Allowed values are 0-255 seconds and are truncated to the nearest integer value.
    public init(_ duration: TimeInterval) {
        self.attentionTimer = UInt8(min(0xFF, duration))
    }
    
    /// Creates the Health Attention Status to disable the Attention Timer on the Element.
    public init() {
        self.attentionTimer = 0
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 1 else {
            return nil
        }
        self.attentionTimer = parameters[0]
    }
    
}
