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

/// A Health Attention Get is an acknowledged message used to get the current Attention Timer state
/// of an Element.
///
/// The Attention Timer is intended to allow an Element to attract human attention and, among others,
/// is used during provisioning.
///
/// When the Attention Timer state is on, the value determines how long (in seconds) the Element shall
/// remain attracting human’s attention. The Element does that by behaving in a human-recognizable
/// way (e.g., a lamp flashes, a motor makes noise, an LED blinks). The exact behavior is implementation
/// specific and depends on the type of device. 
public struct HealthAttentionGet: StaticAcknowledgedMeshMessage {
    public static let opCode: UInt32 = 0x8004
    public static let responseType: StaticMeshResponse.Type = HealthAttentionStatus.self
    
    public var parameters: Data? {
        return nil
    }
    
    /// Creates the Health Attention Get message.
    public init() {
        // Empty
    }
    
    public init?(parameters: Data) {
        guard parameters.isEmpty else {
            return nil
        }
    }
    
}
