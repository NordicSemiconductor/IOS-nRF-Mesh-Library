//
//  UInt16+Hex.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

internal extension UInt16 {
    
    init?(hex: String) {
        guard let value = UInt16(hex, radix: 16) else {
            return nil
        }
        self = value
    }
    
    var hex: String {
        return String(format: "%04X", self)
    }
    
}

public extension UInt16 {
    
    /// Returns the UInt16 as String in HEX format (with 0x).
    ///
    /// Example: "0x0001"
    public func asString() -> String {
        return String(format: "0x%04X", self)
    }
    
}
