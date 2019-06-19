//
//  MeshNetwork+Nodes.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 25/04/2019.
//

import Foundation

public extension MeshNetwork {
    
    /// Returns Provisioner's node object, if such exist and the Provisioner
    /// is in the mesh network.
    ///
    /// - parameter provisioner: The provisioner which node is to be returned.
    ///                          The provisioner must be added to the network
    ///                          before calling this method, otherwise `nil` will
    ///                          be returned. Provisioners without a node assigned
    ///                          do not support configuration operations.
    /// - returns: The Provisioner's node object, or `nil`.
    func node(for provisioner: Provisioner) -> Node? {
        guard hasProvisioner(provisioner) else {
            return nil
        }
        return node(withUuid: provisioner.uuid)
    }
    
    /// Returns the newly added Node for the Unprovisioned Device object.
    ///
    /// - parameter unprovisionedDevice: The device which node is to be returned.
    /// - returns: The Node object, or `nil`, if not found.
    func node(for unprovisionedDevice: UnprovisionedDevice) -> Node? {
        return node(withUuid: unprovisionedDevice.uuid)
    }
    
    /// Returns the first found Node with given UUID.
    ///
    /// - parameter uuid: The Node UUID to look for.
    /// - returns: The Node found, or `nil` if no such exists.
    func node(withUuid uuid: UUID) -> Node? {
        return nodes.first {
            $0.uuid == uuid
        }
    }
    
    /// Returns the Node with given Unicast Address. The address may
    /// be belong to any of the Node's Elements.
    ///
    /// - parameter address: A Unicast Address to look for.
    /// - returns: The Node found, or `nil` if no such exists.
    func node(withAddress address: Address) -> Node? {
        guard address.isUnicast else {
            return nil
        }
        return nodes.first {
            $0.hasAllocatedAddress(address)
        }
    }
    
    /// Returns whether any of the Network Keys in the mesh network
    /// matches the given Network ID.
    ///
    /// - parameter networkId: The Network ID.
    /// - returns: `True` if the Network ID matches any subnetwork of
    ///            this mesh network, `false` otherwise.
    func matches(networkId: Data) -> Bool {
        return networkKeys.contains {
            $0.networkId == networkId
        }
    }
    
    /// Returns whether any of the Nodes in the mesh network matches
    /// given Hash and Random. This is used to match the Node Identity beacon.
    ///
    /// - parameter hash:   The Hash value.
    /// - parameter random: The Random value.
    /// - returns: `True` if the given parameters match any node of this
    ///            mesh network.
    func matches(hash: Data, random: Data) -> Bool {
        let helper = OpenSSLHelper()
        
        for node in nodes {
            // Data are: 48 bits of Padding (0s), 64 bit Random and Unicast Address.
            let data = Data(repeating: 0, count: 6) + random + node.unicastAddress.bigEndian
            
            for networkKey in node.networkKeys {
                let encryptedData = helper.calculateEvalue(with: data, andKey: networkKey.keys.identityKey)!
                if encryptedData.dropFirst(8) == hash {
                    return true
                }
                // If the Key refresh procedure is in place, the identity might have been
                // generated with the old key.
                if let oldIdentityKey = networkKey.oldKeys?.identityKey {
                    let encryptedData = helper.calculateEvalue(with: data, andKey: oldIdentityKey)!
                    if encryptedData.dropFirst(8) == hash {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    /// Adds the Node to the mesh network. If a node with the same UUID
    /// was already in the mesh network, it will be replaced.
    ///
    /// This method should only be used to add debug Nodes, or Nodes
    /// that have already been provisioned. Use `provision(unprovisionedDevice:over)`
    /// to provision and add a Node.
    ///
    /// - parameter node: A Node to be added.
    func add(node: Node) {
        // Verify if the address range is avaialble for the new Node.
        guard isAddressAvailable(node.unicastAddress, elementsCount: node.elementsCount) else {
            print("Error: Address \(node.unicastAddress) is not available")
            return
        }
        if let netKeyIndex = node.netKeys.first?.index,
           !networkKeys.contains(where: { $0.index == netKeyIndex }) {
            print("Error: Network Key Index \(netKeyIndex) does not exist in the network")
            return
        }
        remove(nodeWithUuid: node.uuid)
        
        node.meshNetwork = self
        nodes.append(node)
    }
    
    /// Removes the Node from the mesh network.
    ///
    /// - parameter node: The Node to be removed.
    func remove(node: Node) {
        remove(nodeWithUuid: node.uuid)
    }
    
}
