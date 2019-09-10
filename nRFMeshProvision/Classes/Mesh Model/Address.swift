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
    
    static let unassignedAddress: Address = 0x0000
    static let minUnicastAddress: Address = 0x0001
    static let maxUnicastAddress: Address = 0x7FFF
    static let minVirtualAddress: Address = 0x8000
    static let maxVirtualAddress: Address = 0xBFFF
    static let minGroupAddress:   Address = 0xC000
    static let maxGroupAddress:   Address = 0xFEFF
    
    static let allProxies:        Address = 0xFFFC
    static let allFriends:        Address = 0xFFFD
    static let allRelays:         Address = 0xFFFE
    static let allNodes:          Address = 0xFFFF
    
}

// MARK: - Helper methods

public extension Address {
    
    /// Returns `true` if the address is from a valid range.
    var isValidAddress: Bool {
        return self < 0xFF00 || self > 0xFFFB
    }
    
    /// Returns `true` if the address is an Unassigned Address.
    /// Unassigned addresses is equal to 0b0000000000000000.
    var isUnassigned: Bool {
        return self == Address.unassignedAddress
    }
    
    /// Returns `true` if the address is an Unicat Address.
    /// Unicat addresses match 0b00xxxxxxxxxxxxxx (except 0b0000000000000000).
    var isUnicast: Bool {
        return (self & 0x8000) == 0x0000 && !isUnassigned
    }
    
    /// Returns `true` if the address is a Virtual Address.
    /// Virtual addresses match 0b10xxxxxxxxxxxxxx.
    var isVirtual: Bool {
        return (self & 0xC000) == 0x8000
    }
    
    /// Returns `true` if the address is a Group Address.
    /// Group addresses match 0b11xxxxxxxxxxxxxx.
    var isGroup: Bool {
        return (self & 0xC000) == 0xC000 && isValidAddress
    }
    
    /// Returns `true` if the address is a special Group Address.
    ///
    /// Special groups are:
    /// * All Proxies: 0xFFFC
    /// * All Friends: 0xFFFD
    /// * All Relays: 0xFFFE
    /// * All Nodes: 0xFFFF
    var isSpecialGroup: Bool {
        return self > 0xFFFB
    }
    
}
