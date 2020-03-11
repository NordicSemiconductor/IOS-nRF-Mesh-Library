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

/// The IV Index received with the last Secure Network Beacon and its
/// current state.
///
/// Bluetooth Mesh Profile Specification 1.0.1, Chapter 3.10.5:
///
/// During the Normal Operation state, the IV Update Flag in the Secure Network
/// beacon and in the Friend Update message shall be set to 0. When this state is
/// active, a node shall transmit using the current IV Index and shall process
/// messages from the current IV Index and also the current IV Index - 1.
///
/// During the IV Update in Progress state, the IV Update Flag in the Secure Network
/// beacon and in the Friend Update message shall be set to 1. When this state is
/// active, a node shall transmit using the current IV Index - 1 and shall process
/// messages from the current IV Index - 1 and also the current IV Index.
internal struct IvIndex {
    var index: UInt32 = 0
    var updateActive: Bool = false
    
    /// The IV Index used for transmitting messages.
    var transmitIndex: UInt32 {
        return updateActive && index > 1 ? index - 1 : index
    }
    
    /// The IV Index that is to be used for decrypting messages.
    ///
    /// - parameter ivi: The IVI bit of the received Network PDU.
    /// - returns: The IV Index to be used to decrypt the message.
    func index(for ivi: UInt8) -> UInt32 {
        return ivi == index & 1 ? index : index - 1
    }
}
