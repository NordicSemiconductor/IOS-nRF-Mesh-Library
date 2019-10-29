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

/// The type representing Key Refresh phase.
public enum KeyRefreshPhase: Int, Codable {
    /// Phase 0: Normal Operation.
    case normalOperation  = 0
    /// Phase 1: Distributing new keys to all nodes. Nodes will transmit using
    /// old keys, but can receive using old and new keys.
    case distributingKeys = 1
    /// Phase 2: Transmitting a Secure Network beacon that signals to the network
    /// that all nodes have the new keys. The nodes will then transmit using
    /// the new keys but can receive using the old or new keys, and shall only
    /// receive Secure Network beacons secured using the new Network Key.
    case finalizing       = 2
    
    internal static func from(_ value: Int) -> KeyRefreshPhase? {
        switch value {
        case 0:
            return .normalOperation
        case 1:
            return .distributingKeys
        case 2:
            return .finalizing
        default:
            return nil
        }
    }
}

extension KeyRefreshPhase: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .normalOperation:  return "Normal operation"
        case .distributingKeys: return "Distributing keys"
        case .finalizing:       return "Finalizing"
        }
    }
    
}
