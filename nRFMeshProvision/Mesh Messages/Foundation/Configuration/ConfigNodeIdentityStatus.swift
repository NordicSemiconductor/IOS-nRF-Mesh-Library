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

public struct ConfigNodeIdentityStatus: ConfigResponse, ConfigStatusMessage, ConfigNetKeyMessage {
    public static let opCode: UInt32 = 0x8048
    
    public var parameters: Data? {
        return Data([status.rawValue]) + encodeNetKeyIndex() + identity.rawValue
    }
    
    public let networkKeyIndex: KeyIndex
    public let identity: NodeIdentityState
    public let status: ConfigMessageStatus
    
    /// Creates a Config Node Identity Status object.
    ///
    /// - parameters:
    ///   - identity: The Node Identity state.
    ///   - networkKey: The Network Key.
    ///   - status: The status.
    public init(report identity: NodeIdentityState,
                for networkKey: NetworkKey,
                with status: ConfigMessageStatus) {
        self.networkKeyIndex = networkKey.index
        self.identity = identity
        self.status = status
    }
    
    /// Creates a response to the given request.
    ///
    /// - parameter request: The request has to be of type
    ///                      ``ConfigNodeIdentityGet`` or ``ConfigNodeIdentitySet``.
    public init(responseTo request: ConfigNetKeyMessage) {
        self.networkKeyIndex = request.networkKeyIndex
        // iOS does not support advertising with Node Identity.
        self.identity = .notSupported
        self.status = .success
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 4 else {
            return nil
        }
        guard let status = ConfigMessageStatus(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        networkKeyIndex = Self.decodeNetKeyIndex(from: parameters, at: 1)
        identity = NodeIdentityState(rawValue: parameters[3]) ?? .notSupported
    }
    
}
