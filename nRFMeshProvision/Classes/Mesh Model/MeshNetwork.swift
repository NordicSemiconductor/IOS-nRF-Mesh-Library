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
    
    /// Adds the provisioner.
    ///
    /// - parameter provisioner: The provisioner to be added.
    /// - throws: MeshModelError - if provisioner has allocated invalid ranges
    ///           or ranges overlapping with an existing Provisioner.
    public func add(provisioner: Provisioner) throws {
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
        let node = try Node(for: provisioner, in: self)
        nodes.append(node)
        
        // And finally, add the provisioner.
        provisioners.append(provisioner)
    }
    
    /// Removes provisioner at the given index.
    ///
    /// - parameter index: The position of the element to remove.
    ///                    `index` must be a valid index of the array.
    /// - returns: The removed provisioner.
    public func remove(provisionerAt index: Int) -> Provisioner {
        return provisioners.remove(at: index)
    }
    
    /// Removes the given provisioner. This method does nothing if the
    /// provisioner was not added to the Mesh Network before.
    ///
    /// - parameter provisioner: Provisioner to be removed.
    public func remove(provisioner: Provisioner) {
        if let index = provisioners.firstIndex(where: { $0 === provisioner }) {
            provisioners.remove(at: index)
        }
    }
    
}

// MARK: - Internal MeshNetwork API

extension MeshNetwork {

    /// Returns the next available unicast address from the provisioner's range
    /// that can be assigned to a new node with given number of elements.
    /// The 0'th element is identified by the node's unicast address.
    /// Each following element is identified by a subsequent unicast address.
    ///
    /// - parameter elementsCount: The number of node's elements. Each element will be
    ///                            identified by a subsequent unicast address.
    /// - parameter provisioner:   The provisioner that is creating the node.
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
    
    
}
