//
//  Ranges.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 16/05/2019.
//

import Foundation

public extension RangeObject {
    
    /// Returns whether the given value is in the range.
    ///
    /// - parameter value: The value to be checked.
    /// - returns: `True` if the value is inside the range, `false` otherwise.
    func contains(_ value: UInt16) -> Bool {
        return range.contains(value)
    }
    
    /// Returns a Boolean value indicating whether this range and the given
    /// range contain an element in common.
    ///
    /// - parameter other: A range to check for elements in common.
    /// - returns: `True` if this range and other have at least one element in
    ///            common; otherwise, `false`.
    func overlaps(_ other: RangeObject) -> Bool {
        return range.overlaps(other.range)
    }
    
    /// Returns the closest distance between this and the given range.
    ///
    /// When range 1 ends at 0x1000 and range 2 starts at 0x1002, the
    /// distance between them is 1. If the range 2 starts at 0x0001,
    /// the distance is 0 and they can be merged.
    /// If ranges overlap each other, the distance is 0.
    ///
    /// - parameter range: The range to check distance to.
    /// - returns: The distance between ranges in units.
    func distance(to other: RangeObject) -> UInt16 {
        if upperBound < other.lowerBound {
            return other.lowerBound - upperBound - 1
        }
        if lowerBound > other.upperBound {
            return lowerBound - other.upperBound - 1
        }
        return 0
    }
    
}

public extension Array where Element: RangeObject {
    
    /// Returns a sorted array of ranges. If any ranges were overlapping, they
    /// will be merged.
    ///
    /// - returns: Sorted array of ranges with all overlapping ranges merged.
    func merged() -> [Element] {
        guard count > 1 else {
            return self
        }
        // We have to get the type from the first object, otherwise the result
        // array would be [RangeObject] instead of [AddressRange] or [SceneRange].
        let RangeType = type(of: self.first!)
        
        var result: [Element] = []
        
        var accumulator = RangeType.init(0...0)
        
        for range in sorted(by: { $0.range.lowerBound < $1.range.lowerBound }) {
            // Analyzing first range? Set it as the accumulator.
            if accumulator == 0...0 {
                accumulator = range
            }
            
            // Is the range already in accumulator's range?
            if accumulator.range.upperBound >= range.range.upperBound {
                // Do nothing.
            }
                
                // Does the range start inside the accumulator, or just after the accumulator?
            else if accumulator.range.upperBound + 1 >= range.range.lowerBound {
                // Set the accumulator as merged range.
                accumulator = RangeType.init(accumulator.range.lowerBound...range.range.upperBound)
            }
                
                // There must have been a gap, the accumulator can be appended to result array.
            else /* if accumulator.range.upperBound < range.range.lowerBound */ {
                result.append(accumulator)
                // Initialize the new accumulator as the new range.
                accumulator = range
            }
        }
        
        // Add the last accumulator if it was set above.
        if accumulator != 0...0 {
            result.append(accumulator)
        }
        
        return result
    }
    
    /// Merges all overlapping ranges from the array and sorts them.
    mutating func merge() {
        self = merged()
    }
    
    /// Returns whether the given value is in the range array.
    ///
    /// - parameter address: The value to be checked.
    /// - returns: `True` if the value is inside the range array, `false` otherwise.
    func contains(_ value: UInt16) -> Bool {
        return contains { $0.contains(value) }
    }
    
    /// Returns a Boolean value indicating whether any of the ranges in the array
    /// and the given raneg contain an element in common.
    ///
    /// - parameter other: A range to check for elements in common.
    /// - returns: `True` if this range and other have at least one element in
    ///            common; otherwise, `false`.
    func overlaps(_ other: RangeObject) -> Bool {
        for range in self {
            if range.overlaps(other) {
                return true
            }
        }
        return false
    }
    
    /// Returns a Boolean value indicating whether any of the ranges in the array
    /// and the given array contain an element in common.
    ///
    /// The method does not look for common elements among ranges in the array,
    /// or in the given array, only the cross sections.
    ///
    /// - parameter otherRanges: Ranges to check for elements in common.
    /// - returns: `True` if any of the ranges has at least one element in common;
    ///            with any of ranges from the given array; otherwise, `false`.
    func overlaps(_ otherRanges: [RangeObject]) -> Bool {
        for range in self {
            for other in otherRanges {
                if range.overlaps(other) {
                    return true
                }
            }
        }
        return false
    }
    
}

public extension AddressRange {
    
    /// Returns `true` if the address range is valid. Valid address ranges
    /// are in Unicast or Group ranges.
    ///
    /// - returns: `True` if the address range is in Unicast or Group range,
    ///            `false` otherwise.
    var isValid: Bool {
        return isUnicastRange || isGroupRange
    }
    
    /// Returns `true` if the address range is in Unicast address range
    ///
    /// - returns: `True` if the address range is in Unicast address range,
    ///            `false` otherwise.
    var isUnicastRange: Bool {
        return lowAddress.isUnicast && highAddress.isUnicast
    }
    
    /// Returns `true` if the address range is in Group address range.
    ///
    /// - returns: `True` if the address range is in Group address range,
    ///            `false` otherwise.
    var isGroupRange: Bool {
        return lowAddress.isGroup && highAddress.isGroup
    }
    
}

public extension SceneRange {
    
    /// Returns `true` if the scene range is valid.
    ///
    /// - returns: `True` if the scene range is valid, `false` otherwise.
    var isValid: Bool {
        return firstScene.isValidSceneNumber && lastScene.isValidSceneNumber
    }
    
}

public extension Array where Element == AddressRange {
    
    /// Returns `true` if all the address ranges are valid. Valid address ranges
    /// are in Unicast or Group ranges.
    ///
    /// - returns: `True` if the all address ranges are in Unicast or Group range,
    ///            `false` otherwise.
    var isValid: Bool {
        return !contains{ !$0.isValid }
    }
    
    /// Returns `true` if all the address ranges are of unicast type.
    ///
    /// - returns: `True` if the all address ranges are of unicast type,
    ///            `false` otherwise.
    var isUnicastRange: Bool {
        return !contains{ !$0.isUnicastRange }
    }
    
    /// Returns `true` if all the address ranges are of group type.
    ///
    /// - returns: `True` if the all address ranges are of group type,
    ///            `false` otherwise.
    var isGroupRange: Bool {
        return !contains{ !$0.isGroupRange }
    }
    
}

public extension Array where Element == SceneRange {
    
    /// Returns `true` if all the scene ranges are valid.
    ///
    /// - returns: `True` if the all scene ranges are valid, `false` otherwise.
    var isValid: Bool {
        return !contains{ !$0.isValid }
    }
    
}

// MARK: - Defaults

public extension AddressRange {
    
    static let allUnicastAddresses = AddressRange(Address.minUnicastAddress...Address.maxUnicastAddress)
    
    static let allGroupAddresses = AddressRange(Address.minGroupAddress...Address.maxGroupAddress)
    
}

public extension SceneRange {
    
    static let allScenes: SceneRange = SceneRange(SceneNumber.minScene...SceneNumber.maxScene)
    
}
