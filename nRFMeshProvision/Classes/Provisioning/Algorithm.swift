//
//  Algorithm.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 07/05/2019.
//

import Foundation

public enum Algorithm: UInt8 {
    /// FIPS P-256 Elliptic Curve algorithm will be used to calculate the
    /// shared secret.
    case fipsP256EllipticCurve = 0
}

public struct Algorithms: OptionSet {
    public let rawValue: UInt16
    
    /// FIPS P-256 Elliptic Curve algorithm is supported.
    static let fipsP256EllipticCurve = Algorithms(rawValue: 1 << 0)
    
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    
}

extension Algorithms: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        if rawValue == 0 {
            return "None"
        }
        return [(.fipsP256EllipticCurve, "FIPS P-256 Elliptic Curve")]
            .compactMap { (option, name) in contains(option) ? name : nil }
            .joined(separator: ", ")
    }
    
}
