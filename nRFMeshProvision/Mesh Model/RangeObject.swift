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

/// A base class for an address or scene range.
///
/// Ranges are assigned to ``Provisioner`` objects. Each Provisioner
/// may provision new Nodes, create Groups and Scenes using only values
/// from assigned ranges. The assigned ranges may not overlap with the ranges
/// of other Provisioners, otherwise different instances could reuse the same
/// values leading to collisions.
/// .
public class RangeObject {
    
    public private(set) var range: ClosedRange<UInt16>
    
    /// Lower bound of the range.
    public var lowerBound: UInt16 {
        return range.lowerBound
    }
    
    /// Upper bound of the range.
    public var upperBound: UInt16 {
        return range.upperBound
    }
    
    /// Number of elements in the range.
    public var count: Int {
        return range.count
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

extension RangeObject: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "\(type(of: self)): \(range)"
    }
    
}

// MARK: - Operators
    
public func +<T: RangeObject>(left: T, right: T) -> [T] {
    if left.distance(to: right) == 0 {
        let RangeType = type(of: left)
        return [RangeType.init(min(left.lowerBound, right.lowerBound)...max(left.upperBound, right.upperBound))]
    }
    return [left, right]
}

public func -<T: RangeObject>(left: T, right: T) -> [T] {
    var result: [T] = []
    let RangeType = type(of: left)
    
    // Left:   |------------|                    |-----------|                 |---------|
    //                  -                              -                            -
    // Right:      |-----------------|   or                     |---|   or        |----|
    //                  =                              =                            =
    // Result: |---|                             |-----------|                 |--|
    if right.lowerBound > left.lowerBound {
        let leftSlice = RangeType.init(left.lowerBound...(min(left.upperBound, right.lowerBound - 1)))
        result.append(leftSlice)
    }
    
    // Left:                |----------|             |-----------|                     |--------|
    //                         -                          -                             -
    // Right:      |----------------|           or       |----|          or     |---|
    //                         =                          =                             =
    // Result:                      |--|                      |--|                     |--------|
    if right.upperBound < left.upperBound {
        let rightSlice = RangeType.init(max(right.upperBound + 1, left.lowerBound)...left.upperBound)
        result.append(rightSlice)
    }
    
    return result
}
    
public func +<T: RangeObject>(array: [T], other: T) -> [T] {
    var result = array
    result += other
    return result
}

// This method is not called when 2 arrays are added. It's split
// into 2 below.
/*
public func +<T: RangeObject>(array: [T], otherArray: [T]) -> [T] {
    var result = array
    result += otherArray
    return result
}
*/

public func +(array: [AddressRange], otherArray: [AddressRange]) -> [AddressRange] {
    var result = array
    result += otherArray
    return result
}

public func +(array: [SceneRange], otherArray: [SceneRange]) -> [SceneRange] {
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

// This method is not called when 2 arrays are added. It's split
// into 2 below.
/*
public func +=<T: RangeObject>(array: inout [T], otherArray: [T]) {
    array.append(contentsOf: otherArray)
    array.merge()
}
*/

public func +=(array: inout [AddressRange], otherArray: [AddressRange]) {
    array.append(contentsOf: otherArray)
    array.merge()
}

public func +=(array: inout [SceneRange], otherArray: [SceneRange]) {
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
