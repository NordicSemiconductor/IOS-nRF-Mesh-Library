/*
* Copyright (c) 2025, Nordic Semiconductor
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

import NordicMesh

/// Represents a receiver in the firmware update process.
struct Receiver {
    
    /// The status of the firmware update process.
    enum Status {
        /// The receiver is idle and not currently updating.
        case idle
        /// The receiver is currently distributing the firmware update.
        case distribution(progress: Int, speedBytesPerSecond: Float)
        /// The receiver is in `verificationSucceeded` state.
        case verified
        /// The receiver is in `applyingUpdate` or `applySuccess` state.
        case applied
        /// The receiver is in `verificationFailed`, `applyFailed` or `transferCanceled` state.
        case failure
        
        var progress: Int {
            switch self {
            case .idle: return -1
            case .distribution(let progress, _): return progress
            case .verified: return 100
            case .applied: return 100
            case .failure: return 0
            }
        }
    }
    
    /// The Unicast Address of the Element with the Firmware Update Server model on the Receiver.
    let address: Address
    /// The index of the image being updated.
    let imageIndex: UInt8
    /// The status of the receiver.
    var status: Status = .idle
}
