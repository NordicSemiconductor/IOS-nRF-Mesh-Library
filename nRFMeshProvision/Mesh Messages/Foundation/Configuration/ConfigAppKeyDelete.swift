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

/// A `ConfigAppKeyDelete` is an acknowledged message used to delete an ``ApplicationKey``
/// from the AppKey List on a Node.
///
/// To remove the key from the local Node you may use ``MeshNetwork/remove(applicationKey:force:)``.
///
/// - warning: It is not guaranteed, that the target Node will remove the key from its
///            AppKey List. To make sure the Node gets excluded, use ``ConfigAppKeyUpdate``
///            to update the value of the key and skip the Node when distributing the new
///            value. After the Key Refresh Procedure is complete, the target Node will
///            effectively be excluded from the mesh network.
public struct ConfigAppKeyDelete: AcknowledgedConfigMessage, ConfigNetAndAppKeyMessage {
    public static let opCode: UInt32 = 0x8000
    public static let responseType: StaticMeshResponse.Type = ConfigAppKeyStatus.self
    
    public var parameters: Data? {
        return encodeNetAndAppKeyIndex()
    }
    
    public let networkKeyIndex: KeyIndex
    public let applicationKeyIndex: KeyIndex
    
    /// Creates a ``ConfigAppKeyDelete`` message.
    ///
    /// - Parameter applicationKey: The Application Key to be removed.
    public init(applicationKey: ApplicationKey) {
        self.applicationKeyIndex = applicationKey.index
        self.networkKeyIndex = applicationKey.boundNetworkKey.index
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 3 else {
            return nil
        }
        (networkKeyIndex, applicationKeyIndex) = ConfigAppKeyAdd.decodeNetAndAppKeyIndex(from: parameters, at: 0)
    }
    
}
