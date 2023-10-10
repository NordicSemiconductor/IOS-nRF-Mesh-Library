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

/// A `ConfigAppKeyAdd` is an acknowledged message used to add an ``ApplicationKey``
/// to the AppKey List on a Node and bind it to the ``NetworkKey`` identified by
/// ``NetworkKey/index``.
///
/// The added Application Key can be used by the Node only as a pair with the specified
/// Network Key.
///
/// The Application Key is used to authenticate and decrypt messages it receives,
/// as well as authenticate and encrypt messages it sends.
public struct ConfigAppKeyAdd: AcknowledgedConfigMessage, ConfigNetAndAppKeyMessage {
    public static let opCode: UInt32 = 0x00
    public static let responseType: StaticMeshResponse.Type = ConfigAppKeyStatus.self
    
    public var parameters: Data? {
        return encodeNetAndAppKeyIndex() + key
    }
    
    public let networkKeyIndex: KeyIndex
    public let applicationKeyIndex: KeyIndex
    /// The 128-bit Application Key data.
    public let key: Data
    
    /// Creates a ``ConfigAppKeyAdd`` message.
    ///
    /// Use ``MeshNetwork/add(applicationKey:withIndex:name:)`` to create a new
    /// ``ApplicationKey`` and bind it to selected ``NetworkKey`` using
    /// ``ApplicationKey/bind(to:)``.
    ///
    /// - parameter applicationKey: The Application Key to be added.
    public init(applicationKey: ApplicationKey) {
        self.applicationKeyIndex = applicationKey.index
        self.networkKeyIndex = applicationKey.boundNetworkKey.index
        self.key = applicationKey.key
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 19 else {
            return nil
        }
        (networkKeyIndex, applicationKeyIndex) = Self.decodeNetAndAppKeyIndex(from: parameters, at: 0)
        key = parameters.subdata(in: 3..<19)
    }
    
}
