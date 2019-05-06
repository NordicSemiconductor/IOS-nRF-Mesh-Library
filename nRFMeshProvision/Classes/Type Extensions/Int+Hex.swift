//
//  Int+Hex.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

internal extension UInt16 {
    
    init?(hex: String) {
        guard hex.count == 4, let value = UInt16(hex, radix: 16) else {
            return nil
        }
        self = value
    }
    
    var hex: String {
        return String(format: "%04X", self)
    }
    
    init(data: Data) {
        self = data.withUnsafeBytes { $0.load(as: UInt16.self) }
    }
    
}

internal extension UInt32 {
    
    init?(hex: String) {
        guard hex.count == 4, let value = UInt32(hex, radix: 16) else {
            return nil
        }
        self = value
    }
    
    var hex: String {
        return String(format: "%04X", self)
    }
    
    init(data: Data) {
        self = data.withUnsafeBytes { $0.load(as: UInt32.self) }
    }
    
}
