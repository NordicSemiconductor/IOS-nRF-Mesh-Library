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

/// The unknown message is returned if no local Model defines
/// a message type for the received Op Code.
///
/// The Op Code and raw parameters can be read directly.
///
/// In order to have the Unknown Message parsed, a ``Model`` has to
/// be defined in ``MeshNetworkManager/localElements`` with
/// a ``ModelDelegate`` defining a type for the given Op Code in
/// ``ModelDelegate/messageTypes``.
public struct UnknownMessage: MeshMessage {
    /// The opcode is set when the message is received. Initially it is set
    /// to 0, as the constructor takes only parameters.
    public internal(set) var opCode: UInt32 = 0
    
    public let parameters: Data?
    
    public init?(parameters: Data) {
        self.parameters = parameters
    }    
    
}

extension UnknownMessage: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        let opCodeHex = opCode.hex.suffix(6)
        let parametersHex = parameters?.hex ?? "nil"
        return "UnknownMessage(opCode: 0x\(opCodeHex), parameters: \(parametersHex))"
    }
    
}
