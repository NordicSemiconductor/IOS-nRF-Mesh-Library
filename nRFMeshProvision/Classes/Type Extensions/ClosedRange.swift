//
//  ClosedRange.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 09/04/2019.
//

import Foundation

public extension ClosedRange where Bound == UInt16 {
    
    /// Returns true if the given range is inside (including bounds).
    ///
    /// - parameter other: The outer range.
    /// - returns: `True` if this range is inside the `other` range, `false` otherwise.
    func isInside(_ other: ClosedRange<UInt16>) -> Bool {
        return lowerBound >= other.lowerBound && upperBound <= other.upperBound
    }
    
}
