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

/// The range of addresses of Unicast or Group type.
public class AddressRange: RangeObject, Codable {
    
    /// The lower bound of the range.
    public var lowAddress: Address {
        return range.lowerBound
    }
    
    /// The upper bound of the range.
    public var highAddress: Address {
        return range.upperBound
    }
    
    public convenience init(from address: Address, elementsCount: UInt8) {
        self.init(from: address, to: address + UInt16(elementsCount) - 1)
    }
    
    public convenience init(of node: Node) {
        self.init(node.unicastAddressRange.range)
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case lowAddress
        case highAddress
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lowAddressAsString  = try container.decode(String.self, forKey: .lowAddress)
        let highAddressAsString = try container.decode(String.self, forKey: .highAddress)
        
        guard let lowAddress = Address(hex: lowAddressAsString) else {
            throw DecodingError.dataCorruptedError(forKey: .lowAddress, in: container,
                                                   debugDescription: "Address must be 4-character hexadecimal string.")
        }
        guard let highAddress = Address(hex: highAddressAsString) else {
            throw DecodingError.dataCorruptedError(forKey: .highAddress, in: container,
                                                   debugDescription: "Address must be 4-character hexadecimal string.")
        }
        guard lowAddress.isUnicast || lowAddress.isGroup else {
            throw DecodingError.dataCorruptedError(forKey: .lowAddress, in: container,
                                                   debugDescription: "Low address must be a Unicast or Group address.")
        }
        guard highAddress.isUnicast || highAddress.isGroup else {
            throw DecodingError.dataCorruptedError(forKey: .highAddress, in: container,
                                                   debugDescription: "High address must be a Unicast or Group address.")
        }
        guard (lowAddress.isUnicast && highAddress.isUnicast) || (lowAddress.isGroup && highAddress.isGroup) else {
            throw DecodingError.dataCorruptedError(forKey: .highAddress, in: container,
                                                   debugDescription: "High address of different type than low address.")
        }
        self.init(from: lowAddress, to: highAddress)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(range.lowerBound.hex, forKey: .lowAddress)
        try container.encode(range.upperBound.hex, forKey: .highAddress)
    }
}
