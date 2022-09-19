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

public extension RangeObject {
    
    /// Returns whether the given value is in the range.
    ///
    /// - parameter value: The value to be checked.
    /// - returns: `True` if the value is inside the range, `false` otherwise.
    func contains(_ value: UInt16) -> Bool {
        return range.contains(value)
    }
    
    /// Returns whether the given range is within the range.
    ///
    /// - parameter range: The range to be checked.
    /// - returns: `True` if the range is within the range, `false` otherwise.
    func contains(_ range: RangeObject) -> Bool {
        return contains(range.lowerBound) && contains(range.upperBound)
    }
    
    /// Returns a Boolean value indicating whether the sequence contains an
    /// element that satisfies the given predicate.
    ///
    /// - parameter predicate: A closure that takes an element of the range as its
    ///                        argument and returns a Boolean value that indicates
    ///                        whether the passed element represents a match.
    /// - returns: `True` if the value is inside the range, `false` otherwise.
    func contains(where predicate: (UInt16) -> Bool) -> Bool {
        return range.contains { predicate($0) }
    }
    
    /// Returns a Boolean value indicating whether this range and the given
    /// range contain a common element.
    ///
    /// - parameter other: A range to check for elements in common.
    /// - returns: `True` if this range and other have at least one element in
    ///            common; otherwise, `false`.
    func overlaps(_ other: RangeObject) -> Bool {
        return range.overlaps(other.range)
    }
    
    /// Returns a Boolean value indicating whether this range and the given
    /// array of ranges contain a common element.
    ///
    /// - parameter other: A range to check for elements in common.
    /// - returns: `True` if this range and other have at least one element in
    ///            common; otherwise, `false`.
    func overlaps(_ otherRanges: [RangeObject]) -> Bool {
        return otherRanges.contains { overlaps($0) }
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
        
        var accumulator: Element!
        
        for range in sorted(by: { $0.range.lowerBound < $1.range.lowerBound }) {
            // Analyzing first range? Set it as the accumulator.
            if accumulator == nil {
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
        if accumulator != nil {
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
    
    /// Returns whether the range is within any of the ranges in this array.
    ///
    /// - parameter range: The range to be checked.
    /// - returns: `True` if the range is within the range array, `false` otherwise.
    func contains(_ range: RangeObject) -> Bool {
        return contains { $0.contains(range) }
    }
    
    /// Returns a Boolean value indicating whether any of the ranges in the array
    /// and the given range contain a common element.
    ///
    /// - parameter other: A range to check for elements in common.
    /// - returns: `True` if this range and other have at least one element in
    ///            common; otherwise, `false`.
    func overlaps(_ other: RangeObject) -> Bool {
        return contains { $0.overlaps(other) }
    }
    
    /// Returns a Boolean value indicating whether any of the ranges in the array
    /// and the given array contain a common element.
    ///
    /// The method does not look for common elements among ranges in the array,
    /// or in the given array, only the cross sections.
    ///
    /// - parameter otherRanges: Ranges to check for elements in common.
    /// - returns: `True` if any of the ranges has at least one element in common;
    ///            with any of ranges from the given array; otherwise, `false`.
    func overlaps(_ otherRanges: [RangeObject]) -> Bool {
        return contains { $0.overlaps(otherRanges) }
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

    /// A range containing all valid Unicast Addresses.
    static let allUnicastAddresses = AddressRange(Address.minUnicastAddress...Address.maxUnicastAddress)
    /// A range containing all Group Addresses.
    ///
    /// This range does not exclude Fixed Group Addresses or Virtual Addresses.
    static let allGroupAddresses = AddressRange(Address.minGroupAddress...Address.maxGroupAddress)
    
}

public extension SceneRange {
    
    /// A range containing all valid Scene Numbers.
    static let allScenes: SceneRange = SceneRange(SceneNumber.minScene...SceneNumber.maxScene)
    
}
