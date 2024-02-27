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

/// A `ConfigNetKeyStatus` is an unacknowledged message used to report the status of
/// the operation on the NetKey List.
public struct ConfigNetKeyStatus: ConfigResponse, ConfigStatusMessage, ConfigNetKeyMessage {
    public static let opCode: UInt32 = 0x8044
    
    public var parameters: Data? {
        return Data([status.rawValue]) + encodeNetKeyIndex()
    }
    
    public let networkKeyIndex: KeyIndex
    public let status: ConfigMessageStatus
    
    /// Creates a ``ConfigNetKeyStatus`` message confirming the request.
    ///
    /// - parameter networkKey: The Network Key to confirm.
    public init(confirm networkKey: NetworkKey) {
        self.networkKeyIndex = networkKey.index
        self.status = .success
    }
    
    /// Creates a ``ConfigNetKeyStatus`` message in case of a failure.
    ///
    /// - parameters:
    ///   - request: The request, for which this message is to be sent.
    ///   - status: The response status.
    public init(responseTo request: ConfigNetKeyMessage, with status: ConfigMessageStatus) {
        self.networkKeyIndex = request.networkKeyIndex
        self.status = status
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 3 else {
            return nil
        }
        guard let status = ConfigMessageStatus(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        self.networkKeyIndex = Self.decodeNetKeyIndex(from: parameters, at: 1)
    }
    
}
