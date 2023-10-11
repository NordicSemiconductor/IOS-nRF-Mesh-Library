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
    
    /// Returns whether the Provisioner is in the mesh network.
    ///
    /// - parameter provisioner: The Provisioner to look for.
    /// - returns: `True` if the Provisioner was found, `false` otherwise.
    /// - since: 4.0.0
    func contains(provisioner: Provisioner) -> Bool {
        return contains(provisionerWithUuid: provisioner.uuid)
    }
    
    /// Returns whether the Provisioner with given UUID is in the
    /// mesh network.
    ///
    /// - parameter uuid: The Provisioner's UUID to look for.
    /// - returns: `True` if the Provisioner was found, `false` otherwise.
    /// - since: 4.0.0 
    func contains(provisionerWithUuid uuid: UUID) -> Bool {
        return provisioners.contains { $0.uuid == uuid }
    }
    
    /// Returns the local Provisioner, or `nil` if the mesh network
    /// does not have any.
    ///
    /// - seeAlso: ``setLocalProvisioner(_:)``
    var localProvisioner: Provisioner? {
        return provisioners.first
    }
    
    /// Sets the given Provisioner as the one that will be used for
    /// provisioning new nodes, sending commands, etc. It will be moved
    /// to index 0 in the list of provisioners in the mesh network.
    ///
    /// The Provisioner will be added to the mesh network if it's not
    /// there already. Adding the Provisioner may throw an error,
    /// for example when the ranges overlap with ranges of another
    /// Provisioner or there are no free unicast addresses to be assigned.
    ///
    /// - parameter provisioner: The Provisioner to be used for provisioning.
    /// - throws: An error if adding the Provisioner failed.
    func setLocalProvisioner(_ provisioner: Provisioner) throws {
        if !contains(provisioner: provisioner) {
            try add(provisioner: provisioner)
        }
        
        moveProvisioner(provisioner, toIndex: 0)
    }
    
    /// This method restores the local Provisioner to the one used
    /// last time on this device. If the network is new to this device
    /// this method returns `false`. In that case a new Provisioner
    /// object should be created and set a local Provisioner.
    ///
    /// - important: This library always uses the Provisioner at index 0
    ///              as the local Provisioner. When this method returns
    ///              `false` it does not mean, that there is no local Provisioner
    ///              set, rather that restoring the old one has failed and
    ///              the local one is set to one one that has been already at
    ///              index 0.
    /// - returns: `True`, if the Provisioner has been restored, or
    ///            `false` when the network is new to this device.
    ///            In this case, a new Provisioner should be created
    ///            and set as a local one.
    @discardableResult
    func restoreLocalProvisioner() -> Bool {
        let defaults = UserDefaults(suiteName: uuid.uuidString)!
        
        if let uuidString = defaults.string(forKey: .localProvisionerUuidKey),
           let uuid = UUID(uuidString: uuidString),
           let provisioner = provisioners.first(where: { $0.uuid == uuid }) {
            try! setLocalProvisioner(provisioner)
            return true
        }
        return false
    }
    
    /// Returns whether the given Provisioner is set as the main
    /// Provisioner. The local Provisioner will be used to perform all
    /// provisioning and communication on this device. Every device
    /// should use a different Provisioner to set up devices in the
    /// same mesh network to avoid conflicts with addressing nodes.
    ///
    /// - parameter provisioner: The Provisioner to be checked.
    /// - returns: `True` if the given Provisioner is set up to be the
    ///            main one, `false` otherwise.
    func isLocalProvisioner(_ provisioner: Provisioner) -> Bool {
        return provisioners.first?.uuid == provisioner.uuid
    }
    
    /// Adds the Provisioner and assigns a Unicast Address to it.
    /// This method does nothing if the Provisioner is already added to the
    /// mesh network.
    ///
    /// - parameter provisioner: The Provisioner to be added.
    /// - throws: ``MeshNetworkError`` - if provisioner has allocated invalid ranges
    ///           or ranges overlapping with an existing Provisioner.
    func add(provisioner: Provisioner) throws {
        // Find the Unicast Address to be assigned.
        guard let address = nextAvailableUnicastAddress(for: provisioner) else {
            throw MeshNetworkError.noAddressAvailable
        }
        
        try add(provisioner: provisioner, withAddress: address)
    }
    
    /// Adds the Provisioner and assigns the given Unicast Address to it.
    ///
    /// This method does nothing if the Provisioner is already added to the
    /// mesh network.
    ///
    /// - parameter provisioner:    The Provisioner to be added.
    /// - parameter unicastAddress: The Unicast Address to be used by the Provisioner.
    ///                             A `nil` address means that the Provisioner is not
    ///                             able to perform configuration operations.
    /// - throws: MeshNetworkError - if Provisioner may not be added because it has
    ///           failed the validation. See possible errors for details.
    func add(provisioner: Provisioner, withAddress unicastAddress: Address?) throws {
        // Already added to another network?
        guard provisioner.meshNetwork == nil else {
            throw MeshNetworkError.provisionerUsedInAnotherNetwork
        }
        
        // Is it valid?
        guard provisioner.isValid else {
            throw MeshNetworkError.invalidRange
        }
        
        // Does it have non-overlapping ranges?
        for other in provisioners {
            guard !provisioner.hasOverlappingRanges(with: other) else {
                throw MeshNetworkError.overlappingProvisionerRanges
            }
        }
        
        if let address = unicastAddress {
            // Is the given address inside Provisioner's address range?
            if !provisioner.allocatedUnicastRange.contains(address) {
                throw MeshNetworkError.addressNotInAllocatedRange
            }
            
            // No other node uses the same address?
            guard !nodes.contains(where: { $0.contains(elementWithAddress: address) }) else {
                throw MeshNetworkError.addressNotAvailable
            }
        }
        
        // Is it already added?
        guard !contains(provisioner: provisioner) else {
            return
        }
        
        // Is there a node with the Provisioner's UUID?
        guard !contains(nodeWithUuid: provisioner.uuid) else {
            // The UUID conflict is super unlikely to happen. All UUIDs are
            // randomly generated.
            // TODO: Should a new UUID be autogenerated instead?
            throw MeshNetworkError.nodeAlreadyExist
        }
        
        // Add the Provisioner's Node.
        if let address = unicastAddress {
            let node = Node(for: provisioner, withAddress: address)
            // The new Provisioner will be aware of all currently existing
            // Network and Application Keys.
            node.set(networkKeys: networkKeys)
            node.set(applicationKeys: applicationKeys)
            // Set the Node's Elements.
            if provisioners.isEmpty {
                node.add(elements: localElements)
                node.companyIdentifier = 0x004C // Apple Inc.
                node.minimumNumberOfReplayProtectionList = Address.maxUnicastAddress
            } else {
                node.add(element: .primaryElement)
            }
            // Add the Node to the Network.
            try add(node: node)
        }
        
        // And finally, add the Provisioner.
        provisioner.meshNetwork = self
        provisioners.append(provisioner)
        timestamp = Date()
        
        // When the local Provisioner has been added, save its UUID.
        if provisioners.count == 1 {
            let defaults = UserDefaults(suiteName: uuid.uuidString)!
            defaults.set(provisioner.uuid.uuidString, forKey: .localProvisionerUuidKey)
        }
    }
    
    /// Removes a Provisioner at the given index.
    ///
    /// - important: It is not possible to remove the last Provisioner.
    ///              At least one Provisioner is required.
    /// - parameter index: The position of the element to remove.
    ///                    `index` must be a valid index of the array.
    /// - returns: The removed Provisioner.
    /// - throws: When trying to remove the last Provisioner.
    @discardableResult
    func remove(provisionerAt index: Int) throws -> Provisioner {
        // At least one Provisioner object is required in the mesh network.
        guard provisioners.count > 1 else {
            throw MeshNetworkError.cannotRemove
        }
        
        let localProvisionerRemoved = index == 0
        
        let provisioner = provisioners.remove(at: index)
        remove(nodeForProvisioner: provisioner)
        provisioner.meshNetwork = nil
        
        // If the old local Provisioner has been removed, and a new one
        // has been set on its place, it needs the properties to be updated.
        if localProvisionerRemoved {
            if let n = localProvisioner?.node {
                n.set(networkKeys: networkKeys)
                n.set(applicationKeys: applicationKeys)
                n.companyIdentifier = 0x004C // Apple Inc.
                n.productIdentifier = nil
                n.versionIdentifier = nil
                n.ttl = nil
                n.minimumNumberOfReplayProtectionList = Address.maxUnicastAddress
                // The Element adding has to be done this way. Some Elements may get cut
                // by the property observer when Element addresses overlap other Node's
                // addresses.
                let elements = localElements
                localElements = elements
            }
            
            // When the local Provisioner has changed, save its UUID.
            let defaults = UserDefaults(suiteName: uuid.uuidString)!
            if let provisioner = localProvisioner {
                defaults.set(provisioner.uuid.uuidString, forKey: .localProvisionerUuidKey)
            }
        }
        
        timestamp = Date()
        return provisioner
    }
    
    /// Removes the given Provisioner. This method does nothing if the
    /// Provisioner was not added to the Mesh Network before.
    ///
    /// - important: It is not possible to remove the last Provisioner.
    ///              At least one Provisioner is required.
    /// - parameter provisioner: Provisioner to be removed.
    /// - throws: When trying to remove the last Provisioner.
    func remove(provisioner: Provisioner) throws {
        if let index = provisioners.firstIndex(of: provisioner) {
            try remove(provisionerAt: index)
        }
    }
    
    /// Moves the Provisioner at given index to the new index.
    ///
    /// Both parameters must be valid indices of the collection that are
    /// not equal to `endIndex`. Calling this method with the same index as
    /// both `fromIndex` and `toIndex` has no effect.
    ///
    /// - important: The Provisioner at index 0 is used as local Provisioner.
    /// - parameters:
    ///   - fromIndex: The index of the Provisioner to move.
    ///   - toIndex:   The destination index of the Provisioner.
    func moveProvisioner(fromIndex: Int, toIndex: Int) {
        if fromIndex >= 0 && fromIndex < provisioners.count &&
           toIndex >= 0 && toIndex <= provisioners.count &&
           fromIndex != toIndex {
            let oldLocalProvisioner = toIndex == 0 || fromIndex == 0 ? localProvisioner : nil
            let provisioner = provisioners.remove(at: fromIndex)
            
            // The target index must be modified if the Provisioner is
            // being moved below, as it was removed and other Provisioners
            // were already moved to fill the space.
            let newToIndex = toIndex > fromIndex + 1 ? toIndex - 1 : toIndex
            if newToIndex < provisioners.count {
                provisioners.insert(provisioner, at: newToIndex)
            } else {
                provisioners.append(provisioner)
            }
            timestamp = Date()
            // If a local Provisioner was moved, it's Composition Data must
            // be cleared, as most probably it will be exported to another phone,
            // which will have it's own manufacturer, Elements, etc.
            if newToIndex == 0 || fromIndex == 0, let n = oldLocalProvisioner?.node {
                n.companyIdentifier = nil
                n.productIdentifier = nil
                n.versionIdentifier = nil
                n.ttl = nil
                // After exporting and importing the mesh network configuration on
                // another phone, that phone will update the local Elements array.
                // As the final Elements count is unknown at this place, just add
                // the required Element.
                n.elements.forEach {
                    $0.parentNode = nil
                    $0.index = 0                    
                }
                n.set(elements: [.primaryElement])
            }
            // If a Provisioner was moved to index 0 it becomes the new local Provisioner.
            // The local Provisioner is, by definition, aware of all Network and Application
            // Keys currently existing in the network.
            if newToIndex == 0 || fromIndex == 0 {
                if let n = localProvisioner?.node {
                    n.set(networkKeys: networkKeys)
                    n.set(applicationKeys: applicationKeys)
                    n.companyIdentifier = 0x004C // Apple Inc.
                    n.productIdentifier = nil
                    n.versionIdentifier = nil
                    n.ttl = nil
                    n.minimumNumberOfReplayProtectionList = Address.maxUnicastAddress
                    // The Element adding has to be done this way. Some Elements may get cut
                    // by the property observer when Element addresses overlap other Node's
                    // addresses.
                    let elements = localElements
                    localElements = elements
                }
                // Save the UUID of the local Provisioner.
                let defaults = UserDefaults(suiteName: uuid.uuidString)!
                defaults.set(localProvisioner!.uuid.uuidString, forKey: .localProvisionerUuidKey)
            }
        }
    }
    
    /// Moves the given Provisioner to the new index.
    ///
    /// - important: The Provisioner at index 0 will be used as local Provisioner.
    /// - parameters:
    ///   - provisioner: The Provisioner to be moved.
    ///   - toIndex:     The destination index of the Provisioner.
    func moveProvisioner(_ provisioner: Provisioner, toIndex: Int) {
        if let fromIndex = provisioners.firstIndex(of: provisioner) {
            moveProvisioner(fromIndex: fromIndex, toIndex: toIndex)
        }
    }
    
    /// Changes the Unicast Address used by the given Provisioner.
    ///
    /// If the Provisioner didn't have a Unicast Address specified, the method
    /// will create a Node with given the address. This will enable configuration
    /// capabilities for the Provisioner.
    ///
    /// The Provisioner must be in the mesh network, otherwise an error is thrown.
    ///
    /// - parameters:
    ///   - address:     The new Unicast Address of the Provisioner.
    ///   - provisioner: The Provisioner to be modified.
    /// - throws: An error if the address is not in Provisioner's range,
    ///           or is already used by some other Node in the mesh network.
    func assign(unicastAddress address: Address, for provisioner: Provisioner) throws {
        // Is the Provisioner in the network?
        guard contains(provisioner: provisioner) else {
            throw MeshNetworkError.provisionerNotInNetwork
        }
        
        // Search for Provisioner's node.
        var newNode = false
        var provisionerNode: Node! = node(for: provisioner)
        if provisionerNode == nil {
            newNode = true
            provisionerNode = Node(for: provisioner, withAddress: address)
            // Mark that the Provisioner's Node knows all keys.
            provisionerNode.set(networkKeys: networkKeys)
            provisionerNode.set(applicationKeys: applicationKeys)
            // Set Elements for the Node. Local Node will receive all local Elements.
            if provisioner == localProvisioner {
                provisionerNode.add(elements: localElements)
                provisionerNode.companyIdentifier = 0x004C // Apple Inc.
                provisionerNode.minimumNumberOfReplayProtectionList = Address.maxUnicastAddress
            } else {
                // For other Provisioners, just add the Primary Element. It may happen,
                // that after exporting and importing on another phone the Node will
                // be configured to have more Elements, and its address will have to be
                // changed again to find available range.
                provisionerNode.add(elements: [.primaryElement])
            }
        }
        
        // Is it in Provisioner's range?
        let newRange = AddressRange(from: address, elementsCount: provisionerNode.elementsCount)
        guard provisioner.hasAllocated(addressRange: newRange) else {
            throw MeshNetworkError.addressNotInAllocatedRange
        }
        
        // No other node uses the same address?
        guard isAddress(address, availableFor: provisionerNode) else {
            throw MeshNetworkError.addressNotAvailable
        }
        
        // Finally, if the Node has just been created, add it.
        if newNode {
            try add(node: provisionerNode)
        } else {
            // For a Node that was in the network, it's now safe to update the Address.
            provisionerNode.primaryUnicastAddress = address
        }
        
        if isLocalProvisioner(provisioner) {
            // Reassign local elements. This will ensure they are re-initiated with the
            // new addresses.
            let elements = localElements
            localElements = elements
        }
    }
    
    /// Disables the configuration capabilities by un-assigning Provisioner's address.
    /// Un-assigning an address will delete the Provisioner's Node. This results in the
    /// Provisioner not being able to send or receive mesh messages in the mesh network.
    /// However, the provisioner will still retain it's provisioning capabilities.
    ///
    /// Use ``MeshNetwork/assign(unicastAddress:for:)`` to enable configuration capabilities.
    ///
    /// - parameter provisioner: The Provisioner to be modified.
    func disableConfigurationCapabilities(for provisioner: Provisioner) {
        remove(nodeForProvisioner: provisioner)
    }
    
}

private extension String {
    /// The key used in `UserDefaults` to store the UUID of the local Provisioner for
    /// each loaded mesh network. The intent is to restore the same instance (move to
    /// index 0) whenever the same mesh network configuration is imported.
    ///
    /// Local Provisioner UUID is saved whenever a new Provisioner is added or moved
    /// to index 0 in the ``MeshNetwork/provisioners`` array in mesh network object.
    ///
    /// Use ``MeshNetwork/restoreLocalProvisioner()`` to restore the Provisioner instance.
    static let localProvisionerUuidKey = "provisioner"
}
