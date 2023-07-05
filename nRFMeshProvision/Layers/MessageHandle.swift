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

/// The mesh message handle is returned upon sending a mesh message
/// and allows the message to be cancelled.
///
/// Only segmented or acknowledged messages may be cancelled.
/// Unsegmented unacknowledged messages are sent almost instantaneously
/// (depending on the connection interval and message size)
/// and therefore cannot be cancelled.
///
/// The handle contains information about the message that was sent:
/// its opcode, source and destination addresses.
public struct MessageHandle {
    weak var manager: NetworkManager?

    /// The Op Code of the message.
    public let opCode: UInt32
    /// The source Unicast Address.
    public let source: Address
    /// The destination Address.
    ///
    /// This can be any type of Address.
    public let destination: MeshAddress
    
    init(for message: MeshMessage,
         sentFrom source: Address, to destination: MeshAddress,
         using manager: NetworkManager) {
        self.opCode = message.opCode
        self.source = source
        self.destination = destination
        self.manager = manager
    }
    
    /// Cancels sending the message.
    ///
    /// Only segmented or acknowledged messages may be cancelled.
    /// 
    /// Unsegmented unacknowledged messages are sent almost instantaneously
    /// (depending on the connection interval and message size)
    /// and therefore cannot be cancelled.
    public func cancel() {
        manager?.cancel(messageWithHandler: self)
    }
    
}
