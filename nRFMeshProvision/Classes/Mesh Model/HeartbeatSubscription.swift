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

public struct HeartbeatSubscription: Codable {
    /// The source address for the Heartbeat messages.
    ///
    /// It must be a Unicast Address.
    public let source: Address
    /// The destination address for the Heartbeat messages.
    ///
    /// It can be either a Group or Unicast Address.
    public let destination: Address
    /// A last known value, in seconds, of the period that is used for processing periodic
    /// Heartbeat messages.
    public let period: UInt16
    
    internal init(from source: Address, to destination: Address, for period: UInt16) {
        self.source = source
        self.destination = destination
        self.period = period
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case source
        case destination
        case period
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let sourceAsString = try container.decode(String.self, forKey: .source)
        guard let source = Address(hex: sourceAsString) else {
            throw DecodingError.dataCorruptedError(forKey: .source, in: container,
                                                   debugDescription: "Source address must be 4-character hexadecimal string.")
        }
        guard source.isUnicast else {
            throw DecodingError.dataCorruptedError(forKey: .source, in: container,
                                                   debugDescription: "\(sourceAsString) is not a unicast address.")
        }
        self.source = source
        let destinationAsString = try container.decode(String.self, forKey: .destination)
        guard let destination = Address(hex: destinationAsString) else {
            throw DecodingError.dataCorruptedError(forKey: .destination, in: container,
                                                   debugDescription: "Destination address must be 4-character hexadecimal string.")
        }
        guard destination.isUnicast || destination.isGroup else {
            throw DecodingError.dataCorruptedError(forKey: .destination, in: container,
                                                   debugDescription: "\(destinationAsString) is not a unicast or group address.")
        }
        self.destination = destination
        self.period = try container.decode(UInt16.self, forKey: .period)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(source.hex, forKey: .source)
        try container.encode(destination.hex, forKey: .destination)
        try container.encode(period, forKey: .period)
    }
}

