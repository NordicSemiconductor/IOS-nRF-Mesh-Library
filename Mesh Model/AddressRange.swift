//
//  AddressRange.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

public struct AddressRange: Codable {
    public let lowAddress:  Address
    public let highAddress: Address
    
    public init(from lowAddress: Scene, to highAddress: Scene) {
        self.lowAddress = min(lowAddress, highAddress)
        self.highAddress  = max(lowAddress, highAddress)
    }
    
    public init(_ range: ClosedRange<Scene>) {
        self.init(from: range.lowerBound, to: range.upperBound)
    }
    
    private enum CodingKeys: String, CodingKey {
        case lowAddress
        case highAddress
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lowAddressAsString  = try container.decode(String.self, forKey: .lowAddress)
        let highAddressAsString = try container.decode(String.self, forKey: .highAddress)
        
        guard let lowAddress = Scene(hex: lowAddressAsString) else {
            throw DecodingError.dataCorruptedError(forKey: .lowAddress, in: container,
                                                   debugDescription: "Address must be 4-character hexadecimal string")
        }
        guard let highAddress = Scene(hex: highAddressAsString) else {
            throw DecodingError.dataCorruptedError(forKey: .highAddress, in: container,
                                                   debugDescription: "Address must be 4-character hexadecimal string")
        }
        self.init(from: lowAddress, to: highAddress)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lowAddress.hex,  forKey: .lowAddress)
        try container.encode(highAddress.hex, forKey: .highAddress)
    }
}

// MARK: - Helper methods

public extension AddressRange {
    
    /// Returns true if the address range is valid. Valid address ranges
    /// are in Unicast or Group ranges.
    ///
    /// - returns: True if the address range is in Unicast or Group range.
    public func isValid() -> Bool {
        return isUnicastRange() || isGroupRange()
    }
    
    /// Returns true if the address range is in Unicast address range
    ///
    /// - returns: True if the address range is in Unicast address range.
    public func isUnicastRange() -> Bool {
        return lowAddress.isUnicast() && highAddress.isUnicast()
    }
    
    /// Returns true if the address range is in Group address  range.
    ///
    /// - returns: True if the address range is in Group address  range.
    public func isGroupRange() -> Bool {
        return lowAddress.isGroup() && highAddress.isGroup()
    }
}

public extension Array where Element == AddressRange {
    
    /// Returns true if all the address ranges are valid. Valid address ranges
    /// are in Unicast or Group ranges.
    ///
    /// - returns: True if the all address ranges are in Unicast or Group range.
    public func isValid() -> Bool {
        for range in self {
            if !range.isValid() {
                return false
            }
        }
        return true
    }
    
}

// MARK: - Overlapping

public extension AddressRange {
    
    /// Returns true if this and the given Address Range overlapps.
    ///
    /// - parameter range: The range to check overlapping.
    /// - returns: True if ranges overlap.
    public func overlaps(with other: AddressRange) -> Bool {
        return !doesNotOverlap(with: other)
    }
    
    /// Returns true if this and the given Address Range do not overlap.
    ///
    /// - parameter range: The range to check overlapping.
    /// - returns: True if ranges do not overlap.
    public func doesNotOverlap(with other: AddressRange) -> Bool {
        return (lowAddress < other.lowAddress && highAddress < other.lowAddress)
            || (other.lowAddress < lowAddress && other.highAddress < lowAddress)
    }
    
}

// MARK: - Defaults

public extension AddressRange {
    
    public static let allUnicastAddresses = AddressRange(Address.minUnicastAddress...Address.maxUnicastAddress)
    
    public static let allGroupAddresses = AddressRange(Address.minGroupAddress...Address.maxGroupAddress)
    
}
