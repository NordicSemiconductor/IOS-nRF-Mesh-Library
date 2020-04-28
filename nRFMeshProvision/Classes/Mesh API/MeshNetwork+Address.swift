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

public extension MeshNetwork {
    
    /// Returns whether the given number of unicast addresses starting
    /// from the given one are valid, that is they are all in Unicast
    /// Address range.
    ///
    /// - parameter address: The first address to check.
    /// - parameter count:   Number of addresses to check.
    /// - returns: `True`, if the address range is valid, `false` otherwise.
    func isAddressRangeValid(_ address: Address, elementsCount count: UInt8) -> Bool {
        return address.isUnicast && (address + UInt16(count) - 1).isUnicast
    }
    
    /// Returns whether the given address can be assigned to a new Node
    /// with given number of Elements.
    ///
    /// - parameter address: The first address to check.
    /// - parameter count:   Number of addresses to check.
    /// - parameter node:    The Node, which address is to change. It will be excluded
    ///                      from checking address collisions.
    /// - returns: `True`, if the address range is available, `false` otherwise.
    func isAddressRangeAvailable(_ address: Address, elementsCount count: UInt8, for node: Node? = nil) -> Bool {
        let otherNodes = nodes.filter { $0 != node }
        return isAddressRangeValid(address, elementsCount: count) &&
            !otherNodes.contains { $0.overlapsWithAddress(address, elementsCount: count) }
    }
    
    /// Returns the next available Unicast Address from the Provisioner's range
    /// that can be assigned to a new node with 1 element. The element will be
    /// identified by the returned address.
    ///
    /// - parameters:
    ///   - offset: Minimum Unicast Address to be assigned.
    ///   - provisioner:   The Provisioner that is creating the node.
    ///                    The address will be taken from it's allocated range.
    /// - returns: The next available Unicast Address that can be assigned to a node,
    ///            or `nil`, if there are no more available addresses in the allocated range.
    func nextAvailableUnicastAddress(startingFrom offset: Address = Address.minUnicastAddress,
                                     using provisioner: Provisioner) -> Address? {
        return nextAvailableUnicastAddress(startingFrom: offset, for: 1,
                                           elementsUsing: provisioner)
    }
    
    /// Returns the next available Unicast Address from the Provisioner's range
    /// that can be assigned to a new node with given number of elements.
    /// The 0'th element is identified by the node's Unicast Address.
    /// Each following element is identified by a subsequent Unicast Address.
    ///
    /// - parameters:
    ///   - offset: Minimum Unicast Address to be assigned.
    ///   - elementsCount: The number of Node's elements. Each element will be
    ///                    identified by a subsequent Unicast Address.
    ///   - provisioner:   The Provisioner that is creating the node.
    ///                    The address will be taken from it's allocated range.
    /// - returns: The next available Unicast Address that can be assigned to a node,
    ///            or `nil`, if there are no more available addresses in the allocated range.
    func nextAvailableUnicastAddress(startingFrom offset: Address = Address.minUnicastAddress,
                                     for elementsCount: UInt8,
                                     elementsUsing provisioner: Provisioner) -> Address? {
        let sortedNodes = nodes.sorted { $0.unicastAddress < $1.unicastAddress }
        
        // Iterate through all nodes just once, while iterating over ranges.
        var index = 0
        for range in provisioner.allocatedUnicastRange {
            // Start from the beginning of the current range.
            var address = range.lowAddress
            
            if range.contains(offset) && address < offset {
                address = offset
            }
            
            // Iterate through nodes that weren't checked yet.
            let currentIndex = index
            for _ in currentIndex..<sortedNodes.count {
                let node = sortedNodes[index]
                index += 1
                
                // Skip nodes with addresses below the range.
                if address > node.lastUnicastAddress {
                    continue
                }
                // If we found a space before the current node, return the address.
                if address + UInt16(elementsCount) - 1 < node.unicastAddress {
                    return address
                }
                // Else, move the address to the next available address.
                address = node.lastUnicastAddress + 1
                
                // If the new address is outside of the range, go to the next one.
                if address + UInt16(elementsCount) - 1 > range.highAddress {
                    break
                }
            }
            
            // If the range has available space, return the address.
            if address + UInt16(elementsCount) - 1 <= range.highAddress {
                return address
            }
        }
        // No address was found :(
        return nil
    }
    
    /// Returns the next available Unicast Address from the Provisioner's range
    /// that can be assigned to a new Provisioner's node.
    ///
    /// This method is assuming that the Provisioner has only 1 element.
    ///
    /// - parameter provisioner: The Provisioner that is creating the Node for itself.
    ///                          The address will be taken from it's allocated range.
    /// - returns: The next available Unicast Address that can be assigned to a node,
    ///            or `nil`, if there are no more available addresses in the allocated range.
    func nextAvailableUnicastAddress(for provisioner: Provisioner) -> Address? {
        return nextAvailableUnicastAddress(for: 1, elementsUsing: provisioner)
    }
    
    /// Returns the next available Group Address from the Provisioner's range
    /// that can be assigned to a new Group.
    ///
    /// - parameter provisioner: The Provisioner, which range is to be used for address
    ///                          generation.
    /// - returns: The next available Group Address that can be assigned to a new Group,
    ///            or `nil`, if there are no more available addresses in the allocated range.
    func nextAvailableGroupAddress(for provisioner: Provisioner) -> Address? {
        let sortedGroups = groups.sorted { $0._address < $1._address }
        
        // Iterate through all groups just once, while iterating over ranges.
        var index = 0
        for range in provisioner.allocatedGroupRange {
            // Start from the beginning of the current range.
            var address = range.lowAddress
            
            // Iterate through groups that weren't checked yet.
            let currentIndex = index
            for _ in currentIndex..<sortedGroups.count {
                let group = sortedGroups[index]
                index += 1
                
                // Skip groups with addresses below the range.
                if address > group.address.address {
                    continue
                }
                // If we found a space before the current node, return the address.
                if address < group.address.address {
                    return address
                }
                // Else, move the address to the next available address.
                address = group.address.address + 1
                
                // If the new address is outside of the range, go to the next one.
                if address > range.highAddress {
                    break
                }
            }
            
            // If the range has available space, return the address.
            if address <= range.highAddress {
                return address
            }
        }
        // No address was found :(
        return nil
    }
    
}
