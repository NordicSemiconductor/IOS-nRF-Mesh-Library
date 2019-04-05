//
//  UInt16+String.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 01/04/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

extension UInt16 {
    
    /// Returns the UInt16 as String in HEX format (with 0x).
    ///
    /// Example: "0x0001"
    func asString() -> String {
        return String(format: "0x%04X", self)
    }
    
    /// Returns the UInt16 as String in HEX format.
    ///
    /// Example: "0001"
    var hex: String {
        return String(format: "%04X", self)
    }
}
