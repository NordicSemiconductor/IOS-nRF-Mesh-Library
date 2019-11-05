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

/// The Bluetooth Mesh Network configuration.
public class MeshNetwork: Codable {
    public let schema: String
    public let id: String
    public let version: String
    
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
    /// An array of nodes in the network.
    public internal(set) var nodes: [Node]
    /// An array of groups in teh network.
    public internal(set) var groups: [Group]
    
    /// An array of Elements of the local Provisioner.
    private var _localElements: [Element]
    /// An array of Elements of the local Provisioner.
    internal var localElements: [Element] {
        get {
            return _localElements
        }
        set {
            var elements = newValue
            // Configuration and Health Models will be added automatically.
            // Let's make sure they are not in the array.
            elements.forEach { element in
                element.removePrimaryElementModels()
            }
            // Remove all empty Elements.
            elements = elements.filter { !$0.models.isEmpty }
            // Add the required Models in the Primary Element.
            if elements.isEmpty {
                elements.append(Element(location: .unknown))
            }
            elements[0].addPrimaryElementModels(self)
            
            // Make sure the indexes are correct.
            for (index, element) in elements.enumerated() {
                element.index = UInt8(index)
                element.parentNode = localProvisioner?.node
            }
            _localElements = elements
            // Make sure there is enough address space for all the Elements
            // that are not taken by other Nodes and are in the local Provisioner's
            // address range. If required, cut the Elements array.
            if let provisioner = localProvisioner, let node = provisioner.node {
                var availableElements = elements
                let availableElementsCount = provisioner.maxElementCount(for: node.unicastAddress)
                if availableElementsCount < elements.count {
                    availableElements = elements.dropLast(elements.count - availableElementsCount)
                }
                // Assign the Elements to the Provisioner's Node.
                node.set(elements: availableElements)
            }
        }
    }
    
    internal init(name: String, uuid: UUID = UUID()) {
        schema          = "http://json-schema.org/draft-04/schema#"
        id              = "http://www.bluetooth.com/specifications/assigned-numbers/mesh-profile/cdb-schema.json#"
        version         = "1.0.0"
        meshUUID        = MeshUUID(uuid)
        meshName        = name
        timestamp       = Date()
        provisioners    = []
        networkKeys     = [NetworkKey()]
        applicationKeys = []
        nodes           = []
        groups          = []
        _localElements  = []
        localElements   = [ Element(location: .main) ]
    }
    
    // MARK: - Codable
    
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
        case groups
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schema = try container.decode(String.self, forKey: .schema)
        id = try container.decode(String.self, forKey: .id)
        version = try container.decode(String.self, forKey: .version)
        meshUUID = try container.decode(MeshUUID.self, forKey: .meshUUID)
        meshName = try container.decode(String.self, forKey: .meshName)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        provisioners = try container.decode([Provisioner].self, forKey: .provisioners)
        networkKeys = try container.decode([NetworkKey].self, forKey: .networkKeys)
        applicationKeys = try container.decode([ApplicationKey].self, forKey: .applicationKeys)
        nodes = try container.decode([Node].self, forKey: .nodes)
        groups = try container.decode([Group].self, forKey: .groups)
        
        _localElements = [.primaryElement]
        
        provisioners.forEach {
            $0.meshNetwork = self
        }
        applicationKeys.forEach {
            $0.meshNetwork = self
        }
        nodes.forEach {
            $0.meshNetwork = self
        }
        groups.forEach {
            $0.meshNetwork = self
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
    
    /// Removes the Provisioner's Node from the mesh network.
    ///
    /// - parameter provisioner: Provisioner, which Node should be removed.
    func remove(nodeForProvisioner provisioner: Provisioner) {
        remove(nodeWithUuid: provisioner.uuid)
    }
    
    /// Removes the Node with given UUID from the mesh network.
    ///
    /// - parameter uuid: The UUID of a Node to remove.
    func remove(nodeWithUuid uuid: UUID) {
        if let index = nodes.firstIndex(where: { $0.uuid == uuid }) {
            let node = nodes.remove(at: index)
            // TODO: Verify that no Node is publishing to this Node.
            //       If such Node is found, this method should throw, as
            //       the Node is in use.
            node.meshNetwork = nil
            timestamp = Date()
            
            // Forget the last sequence number for the device.
            let meshUuid = self.uuid
            if let defauts = UserDefaults(suiteName: meshUuid.uuidString) {
                for element in node.elements {
                    defauts.removeObject(forKey: element.unicastAddress.hex)
                }
            }
        }
    }
    
    /// Adds the given Network Key to the network.
    ///
    /// - parameter key: The new Network Key to be added.
    func add(networkKey key: NetworkKey) {
        networkKeys.append(key)
        timestamp = Date()
        
        // Make the local Provisioner aware of the new key.
        if let localProvisioner = provisioners.first,
           let n = node(for: localProvisioner) {
            n.add(networkKey: key)
        }
    }
    
    /// Adds the given Application Key to the network.
    ///
    /// - parameter key: The new Application Key to be added.
    func add(applicationKey key: ApplicationKey) {
        key.meshNetwork = self
        applicationKeys.append(key)
        timestamp = Date()
        
        // Make the local Provisioner aware of the new key.
        if let localProvisioner = provisioners.first,
           let n = node(for: localProvisioner) {
            n.add(applicationKey: key)
        }
    }
    
}
