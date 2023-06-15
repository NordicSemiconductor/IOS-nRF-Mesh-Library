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

/// A `ConfigAppKeyStatus` is an unacknowledged message used to report a status for
/// the requesting message, based on the ``NetworkKey/index`` identifying the
/// ``NetworkKey`` on the NetKey List and on the ``ApplicationKey/index`` identifying
/// the ``ApplicationKey`` on the AppKey List.
public struct ConfigAppKeyStatus: ConfigResponse, ConfigStatusMessage, ConfigNetAndAppKeyMessage {
    public static let opCode: UInt32 = 0x8003  
    
    public var parameters: Data? {
        return Data([status.rawValue]) + encodeNetAndAppKeyIndex()
    }
    
    public let networkKeyIndex: KeyIndex
    public let applicationKeyIndex: KeyIndex
    public let status: ConfigMessageStatus
    
    /// Creates a ``ConfigAppKeyStatus`` message confirming the request.
    ///
    /// - parameter applicationKey: The Application Key to confirm.
    public init(confirm applicationKey: ApplicationKey) {
        self.applicationKeyIndex = applicationKey.index
        self.networkKeyIndex = applicationKey.boundNetworkKey.index
        self.status = .success
    }
    
    /// Creates a ``ConfigAppKeyStatus`` message in case of a failure.
    ///
    /// - parameters:
    ///   - request: The request, for which this message is to be sent.
    ///   - status: The response status.
    public init(responseTo request: ConfigNetAndAppKeyMessage, with status: ConfigMessageStatus) {
        self.applicationKeyIndex = request.applicationKeyIndex
        self.networkKeyIndex = request.networkKeyIndex
        self.status = status
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 4 else {
            return nil
        }
        guard let status = ConfigMessageStatus(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        (networkKeyIndex, applicationKeyIndex) = ConfigAppKeyUpdate.decodeNetAndAppKeyIndex(from: parameters, at: 1)
    }
    
}
