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

/// A base class for Proxy configuration messages.
public protocol ProxyConfigurationMessage: BaseMeshMessage {
    /// The message Op Code.
    var opCode: UInt8 { get }
}

/// A type of a Proxy Configuration message which opcode is known
/// during compilation time.
public protocol StaticProxyConfigurationMessage: ProxyConfigurationMessage {
    /// The message Op Code.
    static var opCode: UInt8 { get }
}

/// A base class for acknowledged proxy configuration messages.
///
/// An acknowledged message is transmitted and acknowledged by each
/// receiving element by responding to that message. The response is
/// typically a status message. If a response is not received within
/// an arbitrary time period, the message will be retransmitted
/// automatically until the timeout occurs.
public protocol AcknowledgedProxyConfigurationMessage: ProxyConfigurationMessage {
    /// The Op Code of the response message.
    var responseOpCode: UInt8 { get }
}

/// A base class static acknowledged proxy configuration messages.
public protocol StaticAcknowledgedProxyConfigurationMessage:
    AcknowledgedProxyConfigurationMessage, StaticProxyConfigurationMessage {
    /// The Type of the response message.
    static var responseType: StaticProxyConfigurationMessage.Type { get }
}

// MARK: - Default values

public extension StaticProxyConfigurationMessage {
    
    var opCode: UInt8 {
        return Self.opCode
    }
    
}

public extension StaticAcknowledgedProxyConfigurationMessage {
    
    var responseOpCode: UInt8 {
        return Self.responseType.opCode
    }
    
}
