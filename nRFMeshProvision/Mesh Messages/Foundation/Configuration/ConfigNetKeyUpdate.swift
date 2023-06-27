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

/// A `ConfigNetKeyUpdate` is an acknowledged message used to update a ``NetworkKey`` on
/// a Node.
///
/// This message initiates a Key Refresh Procedure. The message can be sent to
/// remote nodes which are not scheduled for exclusion (see ``Node/isExcluded``).
///
/// To update the key on the local Node use  ``MeshNetworkManager/sendToLocalNode(_:)``.
///
/// To transition to the next phases of the Key Refresh Procedure use ``ConfigKeyRefreshPhaseSet``.
public struct ConfigNetKeyUpdate: AcknowledgedConfigMessage, ConfigNetKeyMessage {
    public static let opCode: UInt32 = 0x8045
    public static let responseType: StaticMeshResponse.Type = ConfigNetKeyStatus.self
    
    public var parameters: Data? {
        return encodeNetKeyIndex() + key
    }
    
    public let networkKeyIndex: KeyIndex
    /// The 128-bit Application Key data.
    public let key: Data
    
    /// Creates a ``ConfigNetKeyUpdate`` message.
    ///
    /// - parameters:
    ///   - networkKey: The Network Key to be updated.
    ///   - newKey: The new value of the key. The key must be 128-bit long.
    /// - since: 4.0.0
    public init(networkKey: NetworkKey, with newKey: Data) throws {
        guard newKey.count == 16 else {
            throw MeshNetworkError.invalidKey
        }
        self.networkKeyIndex = networkKey.index
        self.key = newKey
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 18 else {
            return nil
        }
        networkKeyIndex = ConfigNetKeyUpdate.decodeNetKeyIndex(from: parameters, at: 0)
        key = parameters.subdata(in: 2..<18)
    }
    
}
