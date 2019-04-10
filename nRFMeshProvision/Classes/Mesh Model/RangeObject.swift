//
//  File.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 10/04/2019.
//

import Foundation

public class RangeObject {
    
    public private(set) var range: ClosedRange<UInt16>
    
    public var lowerBound: Address {
        return range.lowerBound
    }
    
    public var upperBound: Address {
        return range.upperBound
    }
    
    public required init(from lowerBound: UInt16, to upperBound: UInt16) {
        self.range = lowerBound...upperBound
    }
    
    public required init(_ range: ClosedRange<UInt16>) {
        self.range = range
    }
    
}

// MARK: - Operators

extension RangeObject: Equatable {
    
    public static func ==(left: RangeObject, right: RangeObject) -> Bool {
        return left.range == right.range
    }
    
    public static func ==(left: RangeObject, right: ClosedRange<UInt16>) -> Bool {
        return left.range == right
    }
    
    public static func !=(left: RangeObject, right: RangeObject) -> Bool {
        return left.range != right.range
    }
    
    public static func !=(left: RangeObject, right: ClosedRange<UInt16>) -> Bool {
        return left.range != right
    }
    
}

public extension RangeObject {
    
    /// Returns whether the given value is in the range.
    ///
    /// - parameter value: The value to be checked.
    /// - returns: `True` if the value is inside the range, `false` otherwise.
    func contains(_ value: UInt16) -> Bool {
        return range.contains(value)
    }
    
}

public extension Array where Element : RangeObject {
    
    /// Returns a sorted array of ranges. If any ranges were overlapping, they
    /// will be merged.
    ///
    /// - returns: Sorted array of ranges with all overlapping ranges merged.
    func merged() -> [Element] {
        var result: [Element] = []
        
        var accumulator = Element(0...0)
        
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
                accumulator = Element(accumulator.range.lowerBound...range.range.upperBound)
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
}
