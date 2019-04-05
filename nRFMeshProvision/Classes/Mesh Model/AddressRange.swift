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
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case lowAddress
        case highAddress
    }
    
    public init(from decoder: Decoder) throws {
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
        self.init(from: lowAddress, to: highAddress)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lowAddress.hex,  forKey: .lowAddress)
        try container.encode(highAddress.hex, forKey: .highAddress)
    }
}

// MARK: - Operators

extension AddressRange: Equatable {
    
    public static func ==(left: AddressRange, right: AddressRange) -> Bool {
        return left.lowAddress == right.lowAddress && left.highAddress == right.highAddress
    }
    
    public static func ==(left: AddressRange, right: ClosedRange<Address>) -> Bool {
        return left.lowAddress == right.lowerBound && left.highAddress == right.upperBound
    }
    
    public static func !=(left: AddressRange, right: AddressRange) -> Bool {
        return left.lowAddress != right.lowAddress || left.highAddress != right.highAddress
    }
    
    public static func !=(left: AddressRange, right: ClosedRange<Address>) -> Bool {
        return left.lowAddress != right.lowerBound || left.highAddress != right.upperBound
    }
}

// MARK: - Public API

public extension AddressRange {
    
    /// Returns true if the address range is valid. Valid address ranges
    /// are in Unicast or Group ranges.
    ///
    /// - returns: True if the address range is in Unicast or Group range.
    var isValid: Bool {
        return isUnicastRange || isGroupRange
    }
    
    /// Returns true if the address range is in Unicast address range
    ///
    /// - returns: True if the address range is in Unicast address range.
    var isUnicastRange: Bool {
        return lowAddress.isUnicast && highAddress.isUnicast
    }
    
    /// Returns true if the address range is in Group address  range.
    ///
    /// - returns: True if the address range is in Group address  range.
    var isGroupRange: Bool {
        return lowAddress.isGroup && highAddress.isGroup
    }
    
    /// Returns true if this and the given Address Range overlapps.
    ///
    /// - parameter range: The range to check overlapping.
    /// - returns: True if ranges overlap.
    func overlaps(_ other: AddressRange) -> Bool {
        return !doesNotOverlap(other)
    }
    
    /// Returns true if this and the given Address Range do not overlap.
    ///
    /// - parameter range: The range to check overlapping.
    /// - returns: True if ranges do not overlap.
    func doesNotOverlap(_ other: AddressRange) -> Bool {
        return (lowAddress < other.lowAddress && highAddress < other.lowAddress)
            || (other.lowAddress < lowAddress && other.highAddress < lowAddress)
    }
    
    /// Returns whether the given address is in the address range.
    ///
    /// - parameter address: The address to be checked.
    /// - returns: `True` if the address is inside the range.
    func contains(_ address: Address) -> Bool {
        return address >= lowAddress && address <= highAddress
    }
}

public extension Array where Element == AddressRange {
    
    /// Returns true if all the address ranges are valid. Valid address ranges
    /// are in Unicast or Group ranges.
    ///
    /// - returns: True if the all address ranges are in Unicast or Group range.
    var isValid: Bool {
        for range in self {
            if !range.isValid{
                return false
            }
        }
        return true
    }
    
    /// Returns a sorted array of ranges. If any ranges were overlapping, they
    /// will be merged.
    func merged() -> [AddressRange] {
        var result: [AddressRange] = []
        
        var accumulator = AddressRange(0...0)
        
        for range in sorted(by: { $0.lowAddress < $1.lowAddress }) {
            if accumulator == 0...0 {
                accumulator = range
            }
            
            if accumulator.highAddress >= range.highAddress {
                // Range is already in accumulator's range.
            }
                
            else if accumulator.highAddress >= range.lowAddress {
                accumulator = AddressRange(accumulator.lowAddress...range.highAddress)
            }
                
            else /* if accumulator.highAddress < range.lowAddress */ {
                result.append(accumulator)
                accumulator = range
            }
        }
        
        if accumulator != 0...0 {
            result.append(accumulator)
        }
        
        return result
    }
    
    /// Merges all overlapping ranges from the array and sorts them.
    mutating func merge() {
        self = merged()
    }
    
    /// Returns whether the given address is in the address range array.
    ///
    /// - parameter address: The address to be checked.
    /// - returns: `True` if the address is inside the range array.
    func contains(_ address: Address) -> Bool {
        return contains { $0.contains(address) }
    }
}

// MARK: - Defaults

public extension AddressRange {
    
    static let allUnicastAddresses = AddressRange(Address.minUnicastAddress...Address.maxUnicastAddress)
    
    static let allGroupAddresses = AddressRange(Address.minGroupAddress...Address.maxGroupAddress)
    
}
