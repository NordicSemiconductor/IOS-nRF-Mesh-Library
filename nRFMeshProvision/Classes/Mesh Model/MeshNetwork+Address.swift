//
//  MeshNetwork+Address.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 25/04/2019.
//

import Foundation

// MARK: - Internal MeshNetwork API

extension MeshNetwork {
    
    /// Returns the next available unicast address from the Provisioner's range
    /// that can be assigned to a new node with given number of elements.
    /// The 0'th element is identified by the node's unicast address.
    /// Each following element is identified by a subsequent unicast address.
    ///
    /// - parameter elementsCount: The number of node's elements. Each element will be
    ///                            identified by a subsequent unicast address.
    /// - parameter provisioner:   The Provisioner that is creating the node.
    ///                            The address will be taken from it's allocated range.
    /// - returns: The next available unicast address that can be assigned to a node,
    ///            or nil, if there are no more available addresses in the allocated range.
    func nextAvailableUnicastAddress(for elementsCount: UInt16, elementsUsing provisioner: Provisioner) -> Address? {
        let sortedNodes = nodes.sorted { $0.unicastAddress < $1.unicastAddress }
        
        // Iterate through all nodes just once, while iterating over ranges.
        var index = 0
        for range in provisioner.allocatedUnicastRange {
            // Start from the beginning of the current range.
            var address = range.lowAddress
            
            // Iterate through modes that weren't checked yet.
            let currentIndex = index
            for _ in currentIndex..<sortedNodes.count {
                let node = sortedNodes[index]
                index += 1
                
                // Skip nodes with addresses below the range.
                if address > node.lastUnicastAddress {
                    continue
                }
                // If we found a space before the current node, return the address.
                if address + elementsCount - 1 < node.unicastAddress {
                    return address
                }
                // Else, move the address to the next available address.
                address = node.lastUnicastAddress + 1
                
                // If the new address is outside of the range, go to the next one.
                if address + elementsCount - 1 > range.highAddress {
                    break
                }
            }
            
            // If the range has available space, return the address.
            if address + elementsCount - 1 <= range.highAddress {
                return address
            }
        }
        // No address was found :(
        return nil
    }
    
    /// Returns the next available unicast address from the provisioner's range
    /// that can be assigned to a new provisioner's node.
    ///
    /// - parameter provisioner: The provisioner that is creating the node for itself.
    ///                          The address will be taken from it's allocated range.
    /// - returns: The next available unicast address that can be assigned to a node,
    ///            or nil, if there are no more available addresses in the allocated range.
    func nextAvailableUnicastAddress(for provisioner: Provisioner) -> Address? {
        return nextAvailableUnicastAddress(for: 1, elementsUsing: provisioner)
    }
    
}
