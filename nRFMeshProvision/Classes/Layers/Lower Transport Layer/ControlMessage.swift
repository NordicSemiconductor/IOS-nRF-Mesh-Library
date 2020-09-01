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

internal struct ControlMessage: LowerTransportPdu {
    let source: Address
    let destination: Address
    let networkKey: NetworkKey
    let ivIndex: UInt32
    let ttl: UInt8
    
    /// Message Op Code.
    let opCode: UInt8
    
    let upperTransportPdu: Data
    
    var transportPdu: Data {
        return Data() + opCode + upperTransportPdu
    }
    
    let type: LowerTransportPduType = .controlMessage
    
    /// Creates a Control Message from a Network PDU that contains
    /// an unsegmented control message.
    ///
    /// - parameter networkPdu: The received Network PDU with unsegmented
    ///                         Upper Transport message.
    /// - returns: The Control Message object, or `nil`, if the given PDU
    ///            was invalid.
    init?(fromNetworkPdu networkPdu: NetworkPdu) {
        let data = networkPdu.transportPdu
        guard data.count >= 1, data[0] & 0x80 == 0 else {
            return nil
        }
        opCode = data[0] & 0x7F
        upperTransportPdu = data.advanced(by: 1)
        
        source = networkPdu.source
        destination = networkPdu.destination
        networkKey = networkPdu.networkKey
        ivIndex = networkPdu.ivIndex
        ttl = networkPdu.ttl
    }
    
    /// Creates a Control Message object from the given list of segments.
    ///
    /// - parameter segments: List of ordered segments.
    init(fromSegments segments: [SegmentedControlMessage]) {
        // Assuming all segments have the same AID, source and destination addresses and TransMIC.
        let segment = segments.first!
        opCode = segment.opCode
        source = segment.source
        destination = segment.destination
        networkKey = segment.networkKey
        ivIndex = segment.ivIndex
        ttl = segment.ttl
        
        // Segments are already sorted by `segmentOffset`.
        upperTransportPdu = segments.reduce(Data()) {
            $0 + $1.upperTransportPdu
        }
    }
    
    /// Creates a Control Message from the given Proxy Configuration
    /// message. The source should be set to the local Node address.
    /// The given Network Key should be known to the Proxy Node.
    ///
    /// - parameters:
    ///   - message:    The message to be sent.
    ///   - source:     The address of the local Node.
    ///   - networkKey: The Network Key to signe the message with.
    ///                 The key should be known to the connected
    ///                 Proxy Node.
    ///   - ivIndex:    The current IV Index of the mesh network.
    init(fromProxyConfigurationMessage message: ProxyConfigurationMessage,
         sentFrom source: Address, usingNetworkKey networkKey: NetworkKey,
         andIvIndex ivIndex: IvIndex) {
        self.opCode = message.opCode
        self.source = source
        self.destination = Address.unassignedAddress
        self.networkKey = networkKey
        self.ivIndex = ivIndex.transmitIndex
        self.upperTransportPdu = message.parameters ?? Data()
        self.ttl = 0
    }
    
    init(fromHeartbeatMessage heartbeatMessage: HeartbeatMessage,
         usingNetworkKey networkKey: NetworkKey) {
        self.opCode = heartbeatMessage.opCode
        self.source = heartbeatMessage.source
        self.destination = heartbeatMessage.destination
        self.ttl = heartbeatMessage.initialTtl
        self.networkKey = networkKey
        self.ivIndex = heartbeatMessage.ivIndex
        self.upperTransportPdu = heartbeatMessage.transportPdu
    }
}

extension ControlMessage: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "\(type) (opCode: 0x\(opCode.hex), data: 0x\(upperTransportPdu.hex))"
    }
    
}
