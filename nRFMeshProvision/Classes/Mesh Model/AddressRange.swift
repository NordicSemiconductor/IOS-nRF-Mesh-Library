//
//  AddressRange.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

public class AddressRange: RangeObject, Codable {
    
    public var lowAddress: Address {
        return range.lowerBound
    }
    
    public var highAddress: Address {
        return range.upperBound
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
                                                   debugDescription: "Address must be 4-character hexadecimal string")
        }
        guard let highAddress = Address(hex: highAddressAsString) else {
            throw DecodingError.dataCorruptedError(forKey: .highAddress, in: container,
                                                   debugDescription: "Address must be 4-character hexadecimal string")
        }
        guard lowAddress.isUnicast || lowAddress.isGroup else {
            throw DecodingError.dataCorruptedError(forKey: .lowAddress, in: container,
                                                   debugDescription: "Low address must be a Unicast or Group address")
        }
        guard highAddress.isUnicast || highAddress.isGroup else {
            throw DecodingError.dataCorruptedError(forKey: .highAddress, in: container,
                                                   debugDescription: "High address must be a Unicast or Group address")
        }
        guard (lowAddress.isUnicast && highAddress.isUnicast) || (lowAddress.isGroup && highAddress.isGroup) else {
            throw DecodingError.dataCorruptedError(forKey: .highAddress, in: container,
                                                   debugDescription: "High address of different type than low address")
        }
        self.init(from: lowAddress, to: highAddress)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(range.lowerBound.hex, forKey: .lowAddress)
        try container.encode(range.upperBound.hex, forKey: .highAddress)
    }
}
