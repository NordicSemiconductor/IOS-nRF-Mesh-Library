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

/// Bluetooth Mesh address type. Type alias for `UInt16`.
///
/// In Bluetooth mesh addresses are divided into several categories:
/// - Unassigned Address - address 0x0000.
/// - Unicast Addresses - a unique address of an ``Element``.
/// - Group Address - a group address allows sending messages to multiple receivers.
/// - Virtual Group Address - each virtual address is a hash of a Virtual Label (UUID).
/// - Fixed Group Addresses - set of predefined group addresses.
public typealias Address = UInt16

public extension Address {
    
    /// An Unassigned Address is an address in which the Element of a Node
    /// has not been configured yet or no address has been allocated.
    static let unassignedAddress: Address = 0x0000
    static let minUnicastAddress: Address = 0x0001
    static let maxUnicastAddress: Address = 0x7FFF
    static let minVirtualAddress: Address = 0x8000
    static let maxVirtualAddress: Address = 0xBFFF
    static let minGroupAddress:   Address = 0xC000
    static let maxGroupAddress:   Address = 0xFEFF
    
    /// A message sent to the all-proxies address will be processed by the
    /// Primary Element of all nodes that have the friend functionality enabled.
    ///
    /// That means, that Models on the Primary Element of all the Nodes are
    /// automatically subscribed to all-proxies address if the Node has
    /// Proxy functionality enabled. Models on the Primary and other Elements
    /// of a Node may subscribe to this address to receive messages no matter
    /// what the feature state is.
    static let allProxies:        Address = 0xFFFC
    /// A message sent to the all-friends address will be processed by the
    /// Primary Element of all nodes that have the friend functionality enabled.
    ///
    /// That means, that Models on the Primary Element of all the Nodes are
    /// automatically subscribed to all-friends address if the Node has
    /// Friend functionality enabled. Models on the Primary and other Elements
    /// of a Node may subscribe to this address to receive messages no matter
    /// what the feature state is.
    static let allFriends:        Address = 0xFFFD
    /// A message sent to the all-relays address will be processed by the
    /// Primary Element of all nodes that have the relay functionality enabled.
    ///
    /// That means, that Models on the Primary Element of all the Nodes are
    /// automatically subscribed to all-relays address if the Node has
    /// Relay functionality enabled. Models on the Primary and other Elements
    /// of a Node may subscribe to this address to receive messages no matter
    /// what the feature state is.
    static let allRelays:         Address = 0xFFFE
    /// A message sent to the all-nodes address will be processed by the
    /// Primary Element of all nodes.
    ///
    /// That means, that all Models on the Primary Element of all the Nodes
    /// are automatically subscribed to all-nodes address. It is not possible
    /// for Models on other Elements to receive messages sent to All Nodes address,
    /// as they cannot subscribe to this address.
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
    
    /// Returns `true` if the address is an Unicast Address.
    /// Unicast addresses match 0b00xxxxxxxxxxxxxx (except 0b0000000000000000).
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
        return self >= 0xFF00
    }
    
}
