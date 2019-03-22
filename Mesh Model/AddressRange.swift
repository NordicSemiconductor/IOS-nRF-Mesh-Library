//
//  AddressRange.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

public typealias AddressRange = ClosedRange<Address>

// MARK: - Codable

extension ClosedRange: Codable where Bound == Address {
    
    private enum CodingKeys: String, CodingKey {
        case lowerBound = "lowAddress"
        case upperBound = "highAddress"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lowerBound = try container.decode(Address.self, forKey: .lowerBound)
        let upperBound = try container.decode(Address.self, forKey: .upperBound)
        self = lowerBound...upperBound
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lowerBound, forKey: .lowerBound)
        try container.encode(upperBound, forKey: .upperBound)
    }

}

// MARK: - Helper methods

public extension ClosedRange where Bound == Address {
    
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
        return lowerBound.isUnicast() && upperBound.isUnicast()
    }
    
    /// Returns true if the address range is in Group address  range.
    ///
    /// - returns: True if the address range is in Group address  range.
    public func isGroupRange() -> Bool {
        return lowerBound.isGroup() && upperBound.isGroup()
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

public extension ClosedRange where Bound == Address {
    
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
        return (lowerBound < other.lowerBound && upperBound < other.lowerBound)
            || (other.lowerBound < lowerBound && other.upperBound < lowerBound)
    }
    
}

// MARK: - Defaults

public extension ClosedRange where Bound == Address {
    
    public static let allUnicastAddresses = Address.minUnicastAddress...Address.maxUnicastAddress
    
    public static let allGroups = Address.minGroupAddress...Address.maxGroupAddress
    
}
