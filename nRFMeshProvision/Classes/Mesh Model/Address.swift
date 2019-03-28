//
//  Address.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 20/03/2019.
//

import Foundation

/// Bluetooth Mesh address type. Type alias for UInt16.
public typealias Address = UInt16

public extension Address {
    
    public static let unassignedAddress: Address = 0x0000
    public static let minUnicastAddress: Address = 0x0001
    public static let maxUnicastAddress: Address = 0x7FFF
    public static let minVirtualAddress: Address = 0x8000
    public static let maxVirtualAddress: Address = 0xBFFF
    public static let minGroupAddress:   Address = 0xC000
    public static let maxGroupAddress:   Address = 0xFEFF
    
    public static let allProxies:        Address = 0xFFFC
    public static let allFriends:        Address = 0xFFFD
    public static let allRelays:         Address = 0xFFFE
    public static let allNodes:          Address = 0xFFFF
    
}

// MARK: - Helper methods

public extension Address {
    
    /// Returns true if the address is from a valid range.
    public var isValidAddress: Bool {
        return self < 0xFF00 || self > 0xFFFB
    }
    
    /// Returns true if the address is an Unassigned Address.
    /// Unassigned addresses is equal to 0b0000000000000000.
    public var isUnassigned: Bool {
        return self == Address.unassignedAddress
    }
    
    /// Returns true if the address is an Unicat Address.
    /// Unicat addresses match 0b00xxxxxxxxxxxxxx (except 0b0000000000000000).
    public var isUnicast: Bool {
        return (self & 0x8000) == 0x0000 && !isUnassigned
    }
    
    /// Returns true if the address is a Virtual Address.
    /// Virtual addresses match 0b10xxxxxxxxxxxxxx.
    public var isVirtual: Bool {
        return (self & 0xC000) == 0x8000
    }
    
    /// Returns true if the address is a Group Address.
    /// Group addresses match 0b11xxxxxxxxxxxxxx.
    public var isGroup: Bool {
        return (self & 0xC000) == 0xC000
    }
}
