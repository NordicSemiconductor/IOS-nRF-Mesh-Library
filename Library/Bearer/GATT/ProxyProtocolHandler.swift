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

private enum SAR: UInt8 {
    case completeMessage = 0b00
    case firstSegment    = 0b01
    case continuation    = 0b10
    case lastSegment     = 0b11
    
    var value: UInt8 {
        return rawValue << 6
    }
    
    init?(data: Data) {
        self.init(rawValue: data[0] >> 6)
    }
}

private extension PduType {
    
    static func from(_ data: Data) -> PduType? {
        guard data.count > 0 else {
            return nil
        }
        let rawValue = data[0] & 0b00111111
        switch rawValue {
        case 0: return .networkPdu
        case 1: return .meshBeacon
        case 2: return .proxyConfiguration
        case 3: return .provisioningPdu
        default: return nil
        }
    }
    
}

/// This helper class allows segmentation and reassembly (SAR) using
/// the Proxy Protocol defined in Bluetooth Mesh Profile 1.0.1.
public class ProxyProtocolHandler {
    private var buffer: Data?
    private var bufferType: PduType?
    
    /// Default constructor.
    public init() {
        // Empty public init.
    }
    
    /// Segments the given data with given message type to 1+ messages
    /// where all but the last one are of the MTU size and the last one
    /// is MTU size or smaller.
    ///
    /// This method implements the Proxy Protocol from Bluetooth Mesh
    /// specification.
    ///
    /// - parameters:
    ///   - data:        The data to be segmented.
    ///   - messageType: The data type.
    ///   - mtu:         The maximum size of a packet to be sent.
    public func segment(_ data: Data, ofType messageType: PduType, toMtu mtu: Int) -> [Data] {
        var packets: [Data] = []
        
        if data.count <= mtu - 1 {
            // Whole data can fit into a single packet.
            var singlePacket = Data([SAR.completeMessage.value | messageType.rawValue])
            singlePacket += data
            packets.append(singlePacket)
        } else {
            // Data needs to be segmented.
            for i in stride(from: 0, to: data.count, by: mtu - 1) {
                let sar = i == 0 ?
                        SAR.firstSegment :
                        i + mtu - 1 > data.count ?
                            SAR.lastSegment : SAR.continuation
                var singlePacket = Data([sar.value | messageType.rawValue])
                singlePacket += data.subdata(in: i ..< min(data.count, i + mtu - 1))
                packets.append(singlePacket)
            }
        }
        
        return packets
    }
    
    /// This method consumes the given data. If the data were segmented,
    /// they are buffered until the last segment is received.
    /// This method returns the message and its type when the last segment
    /// (or the only one) has been received, otherwise it returns `nil`.
    ///
    /// The packets must be delivered in order. If a new message is
    /// received while the previous one is still reassembled, the old
    /// one will be disregarded. Invalid messages are disregarded.
    ///
    /// - parameter data: The data received.
    /// - returns: The message and its type, or `nil`, if more data
    ///            are expected.
    public func reassemble(_ data: Data) -> (data: Data, messageType: PduType)? {
        guard data.count > 0 else {
            // Disregard invalid packet.
            return nil
        }
        
        guard let sar = SAR(data: data) else {
            // Disregard invalid packet.
            return nil
        }
        
        guard let messageType = PduType.from(data) else {
            // Disregard invalid packet.
            return nil
        }
        
        // Ensure, that only complete message or the first segment may be
        // processed if the buffer is empty.
        guard buffer != nil || sar == .completeMessage || sar == .firstSegment else {
            // Disregard invalid packet.
            return nil
        }
        
        // If the new packet is a continuation/lastSegment, it should have the
        // same message type as the current buffer.
        guard bufferType == nil || bufferType == messageType || sar == .completeMessage || sar == .firstSegment else {
            // Disregard invalid packet.
            return nil
        }

        // If a new message was received while the old one was
        // processed, disregard the old one.
        if buffer != nil && (sar == .completeMessage || sar == .firstSegment) {
            buffer = nil
            bufferType = nil
        }
        
        // Save the message type and append newly received data.
        bufferType = messageType
        if sar == .completeMessage || sar == .firstSegment {
            buffer = Data()
        }
        buffer! += data.subdata(in: 1 ..< data.count)
        
        // If the complete message was received, return it.
        if sar == .completeMessage || sar == .lastSegment {
            let tmp = buffer!
            buffer = nil
            bufferType = nil
            return (data: tmp, messageType: messageType)
        }
        // Otherwise, just return nil.
        return nil
    }
    
}
