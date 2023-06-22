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

public struct ConfigKeyRefreshPhaseSet: AcknowledgedConfigMessage, ConfigNetKeyMessage {
    public static let opCode: UInt32 = 0x8016
    public typealias ResponseType = ConfigKeyRefreshPhaseStatus
    
    public var parameters: Data? {
        return encodeNetKeyIndex() + transition.rawValue
    }
    
    public let networkKeyIndex: KeyIndex
    /// New Key Refresh Phase Transition.
    public let transition: KeyRefreshPhaseTransition
    
    public init(networkKey: NetworkKey, transition: KeyRefreshPhaseTransition) {
        self.networkKeyIndex = networkKey.index
        self.transition = transition
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 3 else {
            return nil
        }
        networkKeyIndex = ConfigKeyRefreshPhaseSet.decodeNetKeyIndex(from: parameters, at: 0)
        guard let t = KeyRefreshPhaseTransition(rawValue: parameters[2]) else {
            return nil
        }
        transition = t
    }
    
}

