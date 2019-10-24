//
//  Node+Address.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 10/05/2019.
//

import Foundation

public extension Node {
    
    /// Number of mode's elements.
    var elementsCount: UInt8 {
        return UInt8(elements.count)
    }
    
    /// The last unicast address allocated to this node. Each node's element
    /// uses its own subsequent unicast address. The first (0th) element is identified
    /// by the node's unicast address. If there are no elements, the last unicast address
    /// is equal to the node's unicast address.
    var lastUnicastAddress: UInt16 {
        // Provisioner may not have any elements
        let allocatedAddresses = Address(elementsCount > 0 ? elementsCount : 1)
        return unicastAddress + allocatedAddresses - 1
    }
    
    /// Returns whether the address uses the given unicast address for one
    /// of its elements.
    ///
    /// - parameter address: Address to check.
    /// - returns: `True` if any of node's elements (or the node itself) was assigned
    ///            the given address, `false` otherwise.
    func hasAllocatedAddress(_ address: Address) -> Bool {
        return address >= unicastAddress && address <= lastUnicastAddress
    }
    
    /// Returns whether the node address range overlaps with the given
    /// address range.
    ///
    /// - parameter address: Address to check.
    /// - parameter count:   Number of following addresses to check.
    /// - returns: `True`, if the node address range overlaps with the given
    ///            range, `false` otherwise.
    func overlapsWithAddress(_ address: Address, elementsCount count: UInt8) -> Bool {
        return !(unicastAddress + UInt16(elementsCount) - 1 < address
              || unicastAddress > address + UInt16(count) - 1)
    }
    
}
