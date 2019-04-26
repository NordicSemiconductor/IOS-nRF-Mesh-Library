//
//  MeshNetwork+Provisioner.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 25/04/2019.
//

import Foundation

// MARK: - MeshNetwork API

public extension MeshNetwork {
    
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
        if !hasProvisioner(provisioner) {
            try add(provisioner: provisioner)
        }
        
        moveProvisioner(provisioner, toIndex: 0)
    }
    
    /// Returns whether the given Provisioner is set as the main
    /// Provisioner. The main Provisioner will be used to perform all
    /// provisioning and communication on this device. Every device
    /// should use a different Provisioner to set up devices in the
    /// same mesh network to avoid conflicts with addressing nodes.
    ///
    /// - parameter provisioner: The Provisioner to be checked.
    /// - returns: `True` if the given Provisioner is set up to be the
    ///            main one, `false` otherwise.
    func isLocalProvisioner(_ provisioner: Provisioner) -> Bool {
        return !provisioners.isEmpty
            && provisioners[0].uuid == provisioner.uuid
    }
    
    /// Adds the provisioner and assignes a unicast address to it.
    /// This method does nothing if the Provisioner is already added to the
    /// mesh network.
    ///
    /// - parameter provisioner: The Provisioner to be added.
    /// - throws: MeshModelError - if provisioner has allocated invalid ranges
    ///           or ranges overlapping with an existing Provisioner.
    func add(provisioner: Provisioner) throws {
        // Find the unicast address to be assigned.
        guard let address = nextAvailableUnicastAddress(for: provisioner) else {
            throw MeshModelError.noAddressAvailable
        }
        
        try add(provisioner: provisioner, withAddress: address)
    }
    
    /// Adds the Provisioner and assign the given unicast address to it.
    /// This method does nothing if the Provisioner is already added to the
    /// mesh network.
    ///
    /// - parameter provisioner:    The Provisioner to be added.
    /// - parameter unicastAddress: The Unicast Address to be used by the Provisioner.
    ///                             A `nil` address means that the Provisioner is not able
    ///                             to perform configuration operations.
    /// - throws: MeshModelError - if Provisioner may not be added beacose it has
    ///           failed the validation. See possible errors for details.
    func add(provisioner: Provisioner, withAddress unicastAddress: Address?) throws {
        // Already added to another network?
        guard provisioner.meshNetwork == nil else {
            throw MeshModelError.provisionerUsedInAnotherNetwork
        }
        
        // Is it valid?
        guard provisioner.isValid else {
            throw MeshModelError.invalidRange
        }
        
        // Does it have non-overlapping ranges?
        for other in provisioners {
            guard !provisioner.hasOverlappingRanges(with: other) else {
                throw MeshModelError.overlappingProvisionerRanges
            }
        }
        
        if let address = unicastAddress {
            // Is the given address inside Provisioner's address range?
            if !provisioner.allocatedUnicastRange.contains(address) {
                throw MeshModelError.addressNotInAllocatedRange
            }
            
            // No other node uses the same address?
            guard !nodes.contains(where: { $0.hasAllocatedAddress(address) }) else {
                throw MeshModelError.addressNotAvailable
            }
        }
        
        // Is it already added?
        guard !hasProvisioner(provisioner) else {
            return
        }
        
        // Is there a node with the provisioner's UUID?
        guard !nodes.contains(where: { $0.uuid == provisioner.uuid }) else {
            // The UUID conflict is super unlikely to happen. All UUIDs are randomly generated.
            throw MeshModelError.nodeAlreadyExist
        }
        
        // Add the provisioner's node.
        if let address = unicastAddress {
            let node = Node(for: provisioner, withAddress: address)
            nodes.append(node)
        }
        
        // And finally, add the provisioner.
        provisioner.meshNetwork = self
        provisioners.append(provisioner)
    }
    
    /// Removes Provisioner at the given index.
    ///
    /// - parameter index: The position of the element to remove.
    ///                    `index` must be a valid index of the array.
    /// - returns: The removed Provisioner.
    func remove(provisionerAt index: Int) -> Provisioner {
        let provisioner = provisioners.remove(at: index)
        
        if let index = nodes.firstIndex(where: { $0.uuid == provisioner.uuid }) {
            nodes.remove(at: index)
        }
        provisioner.meshNetwork = nil
        return provisioner
    }
    
    /// Removes the given Provisioner. This method does nothing if the
    /// Provisioner was not added to the Mesh Network before.
    ///
    /// - parameter provisioner: Provisioner to be removed.
    func remove(provisioner: Provisioner) {
        if let index = provisioners.firstIndex(of: provisioner) {
            _ = remove(provisionerAt: index)
        }
    }
    
    /// Moves the Provisioner at given index to the new index.
    /// Both parameters must be valid indices of the collection that are
    /// not equal to `endIndex`. Calling `moveProvisioner(fromIndex:toIndex:)`
    /// with the same index as both `fromIndex` and `toIndex` has no effect.
    ///
    /// The Provisioner at index 0 will be used as local Provisioner.
    ///
    /// - parameter fromIndex: The index of the Provisioner to move.
    /// - parameter toIndex: The destination index of the Provisioner.
    func moveProvisioner(fromIndex: Int, toIndex: Int) {
        if fromIndex >= 0 && fromIndex < provisioners.count &&
            toIndex >= 0 && toIndex <= provisioners.count &&
            fromIndex != toIndex {
            let provisioner = provisioners.remove(at: fromIndex)
            let newToIndex = toIndex > fromIndex ? toIndex - 1 : toIndex
            if newToIndex <= provisioners.count {
                provisioners.insert(provisioner, at: newToIndex)
            } else {
                provisioners.append(provisioner)
            }
        }
    }
    
    /// Moves the given Provisioner to the new index.
    ///
    /// The Provisioner at index 0 will be used as local Provisioner.
    ///
    /// - parameter provisioner: The Provisioner to be moved.
    /// - parameter toIndex: The destination index of the Provisioner.
    func moveProvisioner(_ provisioner: Provisioner, toIndex: Int) {
        if let fromIndex = provisioners.firstIndex(of: provisioner) {
            moveProvisioner(fromIndex: fromIndex, toIndex: toIndex)
        }
    }
    
    /// Changes the unicast address used by the given Provisioner.
    /// If the Provisioner didn't have a unicast address specified, the method
    /// will create a node with given the unicast address. This will
    /// enable configuration capabilities for the Provisioner.
    /// The Provisioner must be in the mesh network.
    ///
    /// - parameter address:     The new unicast address of the Provisioner.
    /// - parameter provisioner: The provisioner to be modified.
    /// - throws: An error if the address is not in Provisioner's range,
    ///           or is already used by some other node in the mesh network.
    func assign(unicastAddress address: Address, for provisioner: Provisioner) throws {
        // Is the Provisioner in the network?
        guard hasProvisioner(provisioner) else {
            throw MeshModelError.provisionerNotInNetwork
        }
        
        // Is it in Provisioner's range?
        guard provisioner.isInAllocatedRange(address) else {
            throw MeshModelError.addressNotInAllocatedRange
        }
        
        // No other node uses the same address?
        guard !nodes.contains(where: { $0.hasAllocatedAddress(address) }) else {
            throw MeshModelError.addressNotAvailable
        }
        
        // Is there a node with the provisioner's UUID?
        guard !nodes.contains(where: { $0.uuid == provisioner.uuid }) else {
            // The UUID conflict is super unlikely to happen. All UUIDs are randomly generated.
            throw MeshModelError.nodeAlreadyExist
        }
        
        // Search for Provisioner's node.
        if let provisionerNode = node(for: provisioner) {
            provisionerNode.unicastAddress = address
        } else {
            // Not found? The Provisioner without a node may not perform
            // configuration operations. Seems like it will support it from now on.
            let provisionerNode = Node(for: provisioner, withAddress: address)
            nodes.append(provisionerNode)
        }
    }
    
    /// Removes the Provisioner's node. Provisioners without a node
    /// may not perform configuration operations. This method does nothing
    /// if the Provisoner already didn't have a node.
    ///
    /// Use `assign(address:for provisioner)` to enable configuration capabilities.
    ///
    /// - parameter provisioner: The provisioner to be modified.
    func disableConfigurationCapabilities(for provisioner: Provisioner) {
        // Search for Provisioner's node and remove it.
        if let index = nodes.firstIndex(where: { $0.uuid == provisioner.uuid }) {
            nodes.remove(at: index)
        }
    }
    
}


// MARK: - Internal MeshNetwork API

extension MeshNetwork {
    
    /// Returns whether the Provisioner is in the mesh network.
    ///
    /// - parameter provisioner: The Provisioner to look for.
    /// - returns: `True` if the Provisioner was found, `false` otherwise.
    func hasProvisioner(_ provisioner: Provisioner) -> Bool {
        return provisioners.contains(provisioner)
    }
    
    /// Returns whether the Provisioner with given UUID is in the
    /// mesh network.
    ///
    /// - parameter uuid: The Provisioner's UUID to look for.
    /// - returns: `True` if the Provisioner was found, `false` otherwise.
    func hasProvisioner(with uuid: UUID) -> Bool {
        return provisioners.contains { $0.uuid == uuid }
    }

}
