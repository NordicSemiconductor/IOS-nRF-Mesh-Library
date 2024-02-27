/*
* Copyright (c) 2021, Nordic Semiconductor
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

public struct ConfigKeyRefreshPhaseStatus: ConfigResponse, ConfigStatusMessage, ConfigNetKeyMessage {
    public static let opCode: UInt32 = 0x8017
    
    public var parameters: Data? {
        return Data([status.rawValue]) + encodeNetKeyIndex() + UInt8(phase.rawValue)
    }
    
    public let networkKeyIndex: KeyIndex
    public let status: ConfigMessageStatus
    public let phase: KeyRefreshPhase
    
    /// Creates Config Key Refresh Phase Status message with given
    /// error status.
    ///
    /// For successful responses use init(reportPhaseOf:).
    ///
    /// - parameters:
    ///   - request: The request received.
    ///   - error: The error status.
    public init(responseTo request: ConfigNetKeyMessage, with error: ConfigMessageStatus) {
        self.networkKeyIndex = request.networkKeyIndex
        self.status = error
        self.phase = .normalOperation // = 0x00
    }
    
    public init(reportPhaseOf networkKey: NetworkKey) {
        self.networkKeyIndex = networkKey.index
        self.status = .success
        self.phase = networkKey.phase
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 4 else {
            return nil
        }
        guard let status = ConfigMessageStatus(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        networkKeyIndex = ConfigKeyRefreshPhaseSet.decodeNetKeyIndex(from: parameters, at: 1)
        guard let phase = KeyRefreshPhase(rawValue: Int(parameters[3])) else {
            return nil
        }
        self.phase = phase
    }
    
}

