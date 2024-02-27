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

internal struct HeartbeatMessage {
    static let opCode: UInt8 = 0x0A
    
    /// Message Op Code.
    let opCode: UInt8
    /// The Unicast Address of the originating Node.
    let source: Address
    /// The destination Address. This can be either Unicast or Group Address.
    let destination: Address
    /// Currently active features of the Node.
    ///
    /// - If the Relay feature is set, the Relay feature of a Node is in use.
    /// - If the Proxy feature is set, the GATT Proxy feature of a Node is in use.
    /// - If the Friend feature is set, the Friend feature of a Node is in use.
    /// - If the Low Power feature is set, the Node has active relationship with a Friend
    ///   Node.
    let features: NodeFeatures
    /// Initial TTL used when sending the message.
    let initialTtl: UInt8
    /// TTL value with which the Heartbeat message was received.
    ///
    /// This is set to `nil` for outgoing Heartbeat messages.
    let receivedTtl: UInt8?
    
    /// The raw data of Upper Transport Layer PDU.
    let transportPdu: Data
    /// The IV Index used to encode this message.
    let ivIndex: UInt32
    
    /// Number of hops that this message went through.
    var hops: UInt8 {
        guard let receivedTtl = receivedTtl else {
            // Received TTL is nil for outgoing Heartbeat messages.
            return 0
        }
        return initialTtl + 1 - receivedTtl
    }
    
    init?(fromControlMessage message: ControlMessage) {
        opCode = message.opCode
        let data = message.upperTransportPdu
        guard opCode == HeartbeatMessage.opCode, data.count == 3 else {
            return nil
        }
        initialTtl = data[0] & 0x7F
        features = NodeFeatures(rawValue: UInt16(data[1] << 8) | UInt16(data[2]))
        
        source = message.source
        destination = message.destination
        receivedTtl = message.ttl
        ivIndex = message.ivIndex
        transportPdu = message.upperTransportPdu
    }
    
    /// Creates a Heartbeat message.
    ///
    /// - Parameters:
    ///   - heartbeatPublication: The publication based on which the Heartbeat message
    ///                           is generated.
    ///   - source: The originating Unicast Address.
    ///   - destination: The destination Unicast or Group Address.
    init(basedOn heartbeatPublication: HeartbeatPublication,
         from source: Address, targeting destination: Address,
         usingIvIndex ivIndex: IvIndex) {
        self.opCode = HeartbeatMessage.opCode
        self.initialTtl = heartbeatPublication.ttl
        self.features = [] // nRF Mesh on iOS library does not support any of the features.
        self.source = source
        self.destination = destination
        self.receivedTtl = nil
        self.ivIndex = ivIndex.transmitIndex
        self.transportPdu = Data() + (initialTtl & 0x7F) + features.rawValue
    }
}

extension HeartbeatMessage: CustomDebugStringConvertible {
    
    var debugDescription: String {
        if let receivedTtl = receivedTtl {
            return "Heartbeat Message (initial TTL: \(initialTtl), received TTL: \(receivedTtl), " +
                   "hops: \(hops), features: \(features))"
        } else {
            return "Heartbeat Message (initial TTL: \(initialTtl), features: \(features))"
        }
    }
    
}
