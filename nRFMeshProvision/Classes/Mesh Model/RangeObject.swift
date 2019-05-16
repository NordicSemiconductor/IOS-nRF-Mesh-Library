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
