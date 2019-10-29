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
    
    /// Returns Provisioner's Node object, if such exist and the Provisioner
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
    /// - throws: This method throws if the Node's address is not available,
    ///           the Node does not have a Network Key, or the Network Key does
    ///           not belong to the mesh network.
    func add(node: Node) throws {
        // Verify if the address range is avaialble for the new Node.
        guard isAddressRangeAvailable(node.unicastAddress, elementsCount: node.elementsCount) else {
            throw MeshNetworkError.addressNotAvailable
        }
        // Ensure the Network Key exists.
        guard let netKeyIndex = node.netKeys.first?.index else {
            throw MeshNetworkError.noNetworkKey
        }
        // Make sure the network contains a Network Key with the same Key Index.
        guard networkKeys.contains(where: { $0.index == netKeyIndex }) else {
            throw MeshNetworkError.invalidKey
        }
        remove(nodeWithUuid: node.uuid)
        
        node.meshNetwork = self
        nodes.append(node)
        timestamp = Date()
    }
    
    /// Removes the Node from the mesh network.
    ///
    /// - parameter node: The Node to be removed.
    func remove(node: Node) {
        remove(nodeWithUuid: node.uuid)
    }
    
}
