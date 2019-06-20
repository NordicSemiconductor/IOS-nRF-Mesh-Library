//
//  RangeObject.swift
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

// MARK: - Operators
    
public func +<T: RangeObject>(left: T, right: T) -> [T] {
    if left.distance(to: right) == 0 {
        return [T(min(left.lowerBound, right.lowerBound)...max(left.upperBound, right.upperBound))]
    }
    return [left, right]
}

public func -<T: RangeObject>(left: T, right: T) -> [T] {
    var result: [T] = []
    
    // Left:   |------------|                    |-----------|                 |---------|
    //                  -                              -                            -
    // Right:      |-----------------|   or                     |---|   or        |----|
    //                  =                              =                            =
    // Result: |---|                             |-----------|                 |--|
    if right.lowerBound > left.lowerBound {
        let leftSlice = T(left.lowerBound...(min(left.upperBound, right.lowerBound - 1)))
        result.append(leftSlice)
    }
    
    // Left:                |----------|             |-----------|                     |--------|
    //                         -                          -                             -
    // Right:      |----------------|           or       |----|          or     |---|
    //                         =                          =                             =
    // Result:                      |--|                      |--|                     |--------|
    if right.upperBound < left.upperBound {
        let rightSlice = T(max(right.upperBound + 1, left.lowerBound)...left.upperBound)
        result.append(rightSlice)
    }
    
    return result
}
    
public func +<T: RangeObject>(array: [T], other: T) -> [T] {
    var result = array
    result += other
    return result
}

public func +<T: RangeObject>(array: [T], otherArray: [T]) -> [T] {
    var result = array
    result += otherArray
    return result
}

public func -<T: RangeObject>(array: [T], other: T) -> [T] {
    var result = array
    result -= other
    return result
}

public func -<T: RangeObject>(array: [T], otherArray: [T]) -> [T] {
    var result = array
    result -= otherArray
    return result
}

public func +=<T: RangeObject>(array: inout [T], other: T) {
    array.append(other)
    array.merge()
}

public func +=<T: RangeObject>(array: inout [T], otherArray: [T]) {
    array.append(contentsOf: otherArray)
    array.merge()
}

public func -=<T: RangeObject>(array: inout [T], other: T)  {
    var result: [T] = []
    
    for this in array {
        result += this - other
    }
    array.removeAll()
    array.append(contentsOf: result)
}

public func -=<T: RangeObject>(array: inout [T], otherArray: [T]) {
    otherArray.forEach {
        array -= $0
    }
}
