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

public struct HeartbeatPublication: Codable {
    /// The destination address for the Heartbeat messages.
    /// 
    /// It can be either a Group or Unicast Address.
    public let address: Address
    /// The cadence of periodical Heartbeat messages in seconds.
    public let period: UInt16
    /// The TTL (Time to Live) value for the Heartbeat messages.
    public let ttl: UInt8
    /// The index property contains an integer that represents a network key index,
    /// indicating which network key to use for the Heartbeat publication.
    ///
    /// The Network Key Index corresponds to the index value of one of the Network Key
    /// entries in Node `networkKeys` array.
    public let networkKeyIndex: KeyIndex
    /// An array of features that trigger sending Heartbeat messages when changed.
    public let features: [NodeFeature]
    
    internal init(to address: Address, for period: UInt16, secondsWithTtl ttl: UInt8,
                using networkKey: NetworkKey, on features: [NodeFeature]) {
        self.address = address
        self.period = period
        self.ttl = ttl
        self.networkKeyIndex = networkKey.index
        self.features = features
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case address
        case period
        case ttl
        case networkKeyIndex = "index"
        case features
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let addressAsString = try container.decode(String.self, forKey: .address)
        guard let address = Address(hex: addressAsString) else {
            throw DecodingError.dataCorruptedError(forKey: .address, in: container,
                                                   debugDescription: "Address must be 4-character hexadecimal string.")
        }
        guard address.isUnicast || address.isGroup else {
            throw DecodingError.dataCorruptedError(forKey: .address, in: container,
                                                   debugDescription: "\(addressAsString) is not a unicast or group address.")
        }
        self.address = address
        self.period = try container.decode(UInt16.self, forKey: .period)
        let ttl = try container.decode(UInt8.self, forKey: .ttl)
        guard ttl <= 127 else {
            throw DecodingError.dataCorruptedError(forKey: .ttl, in: container,
                                                   debugDescription: "TTL must be in range 0-127.")
        }
        self.ttl = ttl
        self.networkKeyIndex = try container.decode(KeyIndex.self, forKey: .networkKeyIndex)
        self.features = try container.decode([NodeFeature].self, forKey: .features)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(address.hex, forKey: .address)
        try container.encode(period, forKey: .period)
        try container.encode(ttl, forKey: .ttl)
        try container.encode(networkKeyIndex, forKey: .networkKeyIndex)
        try container.encode(features, forKey: .features)
    }
}
