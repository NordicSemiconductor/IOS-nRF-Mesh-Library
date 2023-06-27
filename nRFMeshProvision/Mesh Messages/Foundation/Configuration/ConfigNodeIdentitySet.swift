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

public struct ConfigNodeIdentitySet: AcknowledgedConfigMessage, ConfigNetKeyMessage {
    public static let opCode: UInt32 = 0x8047
    public static let responseType: StaticMeshResponse.Type = ConfigNodeIdentityStatus.self
    
    public var parameters: Data? {
        return encodeNetKeyIndex() + identity.rawValue
    }
    
    public let networkKeyIndex: KeyIndex
    /// The Node Identity state determines if a node is advertising with Node Identity
    /// messages on a subnet.
    public let identity: NodeIdentityState
    
    /// Creates the Config Node Identity Set message.
    ///
    /// - parameters:
    ///   - networkKey: The Network Key index for requested subnet.
    ///   - identity:   The Node Identity state determines if a node is advertising with
    ///                 Node Identity messages on a subnet.
    public init(networkKey: NetworkKey, identity: NodeIdentityState) {
        self.networkKeyIndex = networkKey.index
        self.identity = identity
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 3 else {
            return nil
        }
        networkKeyIndex = Self.decodeNetKeyIndex(from: parameters, at: 0)
        identity = NodeIdentityState(rawValue: parameters[2]) ?? .notSupported
    }
}
