//
//  MeshNetwork.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 19/03/2019.
//

import Foundation

/// The Bluetooth Mesh Network configuration.
public class MeshNetwork: Codable {
    public let schema  = "http://json-schema.org/draft-04/schema#"
    public let id      = "TBD"
    public let version = "1.0.0"
    
    /// Random 128-bit UUID allows differentiation among multiple mesh networks.
    internal let meshUUID: MeshUUID
    /// Random 128-bit UUID allows differentiation among multiple mesh networks.
    public var uuid: UUID {
        return meshUUID.uuid
    }
    /// The last time the Provisioner database has been modified.
    public internal(set) var timestamp: Date
    /// UTF-8 string, which should be human readable name for this mesh network.
    public var meshName: String {
        didSet {
            timestamp = Date()
        }
    }
    /// An array of provisioner objects that includes information about known
    /// Provisioners and ranges of addresses that have been allocated to these
    /// Provisioners.
    public internal(set) var provisioners: [Provisioner]
    /// An array of network keys that include information about network keys
    /// used in the network.
    public internal(set) var networkKeys: [NetworkKey]
    /// An array of application keys that include information about application
    /// keys used in the network.
    public internal(set) var applicationKeys: [ApplicationKey]
    // An array of nodes in the network.
    public internal(set) var nodes: [Node]
    
    /// Coding keys used to export / import Mesh Network.
    enum CodingKeys: String, CodingKey {
        case schema          = "$schema"
        case id
        case version
        case meshUUID
        case meshName
        case timestamp
        case provisioners
        case networkKeys     = "netKeys"
        case applicationKeys = "appKeys"
        case nodes
    }
    
    internal init(name: String, uuid: UUID = UUID()) {
        meshUUID        = MeshUUID(uuid)
        meshName        = name
        timestamp       = Date()
        provisioners    = []
        networkKeys     = []
        applicationKeys = []
        nodes           = []
    }
}

// MARK: - MeshNetwork API

public extension MeshNetwork {
    
    /// Returns whether there are Provisioners in the mesh network.
    ///
    /// - returns: `True` if at least one Provisoner has been added to the
    ///            mesh network, `false` otherwise.
    func hasProvisioners() -> Bool {
        return provisioners.isEmpty == false
    }
    
    /// Returns whether there are other Provisioners in the mesh network
    /// except the local one.
    ///
    /// - returns: `True` if at least two Provisoner have been added to the
    ///            mesh network, `false` otherwise.
    func hasOtherProvisioners() -> Bool {
        return provisioners.count > 1
    }
    
    /// Adds the provisioner and assignes a unicast address to it.
    /// This method does nothing if the Provisioner is already added to the
    /// mesh network.
    ///
    /// - parameter provisioner: The provisioner to be added.
    /// - throws: MeshModelError - if provisioner has allocated invalid ranges
    ///           or ranges overlapping with an existing Provisioner.
    func add(provisioner: Provisioner) throws {
        // Find the unicast address to be assigned.
        guard let address = allocateNextAvailableUnicastAddress(for: provisioner) else {
            throw MeshModelError.noAddressAvailable
        }
        
        try add(provisioner: provisioner, withAddress: address)
    }
    
    /// Adds the Provisioner and assign the given unicast address to it.
    /// This method does nothing if the Provisioner is already added to the
    /// mesh network.
    ///
    /// - parameter provisioner:    The provisioner to be added.
    /// - parameter unicastAddress: The unicast address to be used by the Provisioner.
    ///                             A `nil` address means that the Provisioner is not able
    ///                             to perform configuration operations.
    /// - throws: MeshModelError - if provisioner has allocated invalid ranges
    ///           or ranges overlapping with an existing Provisioner.
    func add(provisioner: Provisioner, withAddress unicastAddress: Address?) throws {
        // Is it valid?
        guard provisioner.isValid else {
            throw MeshModelError.provisionerRangesNotAllocated
        }
        
        // Does it have non-overlapping ranges?
        for other in provisioners {
            guard !provisioner.hasOverlappingRanges(with: other) else {
                throw MeshModelError.overlappingProvisionerRanges
            }
        }
        
        // Is the given address inside Provisioner's address range?
        if let address = unicastAddress {
            if !provisioner.allocatedUnicastRange.contains(address) {
                throw MeshModelError.addressNotInAllocatedRange
            }
        }
        
        // Is it already added?
        guard !provisioners.contains(provisioner) else {
            return
        }
        
        // Is there a node with the provisioner's UUID?
        for node in nodes {
            if node.uuid == provisioner.uuid {
                throw MeshModelError.nodeAlreadyExist
            }
        }
        
        // Add the provisioner's node.
        if let address = unicastAddress {
            let node = Node(for: provisioner, withAddress: address)
            nodes.append(node)
        }
        
        // And finally, add the provisioner.
        provisioners.append(provisioner)
    }
    
    /// Removes provisioner at the given index.
    ///
    /// - parameter index: The position of the element to remove.
    ///                    `index` must be a valid index of the array.
    /// - returns: The removed provisioner.
    func remove(provisionerAt index: Int) -> Provisioner {
        let provisioner = provisioners.remove(at: index)
        
        if let index = nodes.firstIndex(where: { $0.uuid == provisioner.uuid }) {
            nodes.remove(at: index)
        }
        return provisioner
    }
    
    /// Removes the given provisioner. This method does nothing if the
    /// provisioner was not added to the Mesh Network before.
    ///
    /// - parameter provisioner: Provisioner to be removed.
    func remove(provisioner: Provisioner) {
        if let index = provisioners.firstIndex(of: provisioner) {
            _ = remove(provisionerAt: index)
        }
    }
    
    /// Returns Provisioner's node object, if such exist and the Provisioner
    /// is in the mesh network.
    ///
    /// - parameter provisioner: The provisioner which node is to be returned.
    ///                          The provisioner must be added to the network
    ///                          before calling this method, otherwise nil will
    ///                          be returned. Provisioners without node assigned
    ///                          do not support configuration operations.
    /// - returns: The Provisioner's node object.
    func node(for provisioner: Provisioner) -> Node? {
        if let index = nodes.firstIndex(where: { $0.uuid == provisioner.uuid }) {
            return nodes[index]
        }
        return nil
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
        guard nodes.contains(where: { $0.hasAllocatedAddress(address) }) == false else {
            throw MeshModelError.noAddressAvailable
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
        return provisioners.contains { $0.uuid == provisioner.uuid }
    }
    
    /// Returns whether the Provisioner with given UUID is in the
    /// mesh network.
    ///
    /// - parameter uuid: The Provisioner's UUID to look for.
    /// - returns: `True` if the Provisioner was found, `false` otherwise.
    func hasProvisioner(with uuid: UUID) -> Bool {
        return provisioners.contains { $0.uuid == uuid }
    }
    
    /// Sets the given Provisoner as the local one.
    /// The local one will be placed in the provisioners list at index 0.
    ///
    /// - parameter provisioner: The Provisioner to be brought to the
    ///                          from of the provisioners array.
    func setMainProvisioner(_ provisioner: Provisioner) {
        if let index = provisioners.firstIndex(of: provisioner), index > 0 {
            provisioners.remove(at: index)
            provisioners.insert(provisioner, at: 0)
        }
    }

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
    func allocateNextAvailableUnicastAddress(for elementsCount: UInt16, elementsUsing provisioner: Provisioner) -> Address? {
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
    func allocateNextAvailableUnicastAddress(for provisioner: Provisioner) -> Address? {
        return allocateNextAvailableUnicastAddress(for: 1, elementsUsing: provisioner)
    }    
    
}
