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
///
/// The mesh network object contains information about known Nodes, Provisioners,
/// Network and Application Keys, Groups and Scenes, as well as the exclusion list.
/// The configuration does not contain any sequence numbers, IV Index, or other
/// network properties that change without the action from the Provisioner.
///
/// The structure of this class is compatible with Mesh Configuration Database 1.0.1.
public class MeshNetwork: Codable {
    /// Random 128-bit UUID allows differentiation among multiple mesh networks.
    public let uuid: UUID
    /// The last time the Provisioner database has been modified.
    public internal(set) var timestamp: Date
    /// Whether the configuration contains full information about the mesh network,
    /// or only partial. In partial configuration Nodes' Device Keys can be `nil`.
    public let isPartial: Bool
    /// UTF-8 string, which should be human readable name for this mesh network.
    public var meshName: String {
        didSet {
            timestamp = Date()
        }
    }
    /// An array of provisioner objects that includes information about known
    /// Provisioners and ranges of addresses and scenes that have been allocated
    /// to these Provisioners.
    public internal(set) var provisioners: [Provisioner]
    /// An array that include information about Network Keys used in the
    /// network.
    public internal(set) var networkKeys: [NetworkKey]
    /// An array that include information about Application Keys used in the
    /// network.
    public internal(set) var applicationKeys: [ApplicationKey]
    /// An array of Nodes in the network.
    public internal(set) var nodes: [Node]
    /// An array of Groups in the network.
    public internal(set) var groups: [Group]
    /// An array of Scenes in the network.
    public internal(set) var scenes: [Scene]
    /// An array containing Unicast Addresses that cannot be assigned to new Nodes.
    internal var networkExclusions: [ExclusionList]?
    
    /// The IV Index of the mesh network.
    internal var ivIndex: IvIndex {
        didSet {
            // Clean up the network exclusions.
            networkExclusions?.cleanUp(forIvIndex: ivIndex)
            if networkExclusions?.isEmpty ?? false {
                networkExclusions = nil
            }
        }
    }
    
    /// An array of Elements of the local Provisioner.
    private var _localElements: [Element]
    /// An array of Elements of the local Provisioner.
    internal var localElements: [Element] {
        get {
            return _localElements
        }
        set {
            var elements = newValue
            // Some models, which are supported by the library, will be added automatically.
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
                let availableElementsCount = provisioner.maxElementCount(for: node.primaryUnicastAddress)
                if availableElementsCount < elements.count {
                    availableElements = elements.dropLast(elements.count - availableElementsCount)
                }
                // Assign the Elements to the Provisioner's Node.
                node.set(elements: availableElements)
            }
        }
    }
    
    internal init(name: String, uuid: UUID = UUID()) {
        self.uuid              = uuid
        self.meshName          = name
        self.isPartial         = false
        self.timestamp         = Date()
        self.provisioners      = []
        self.networkKeys       = [NetworkKey()]
        self.applicationKeys   = []
        self.nodes             = []
        self.groups            = []
        self.scenes            = []
        self.networkExclusions = []
        self.ivIndex           = IvIndex()
        self._localElements    = []
        self.localElements     = [Element(location: .main)]
    }
    
    internal init(copy network: MeshNetwork, using configuration: ExportConfiguration) {
        self.uuid              = network.uuid
        self.meshName          = network.meshName
        self.timestamp         = network.timestamp
        self.ivIndex           = network.ivIndex
        self.networkExclusions = network.networkExclusions
        self._localElements    = []
        
        switch configuration {
        case .full:
            self.isPartial = false
            self.provisioners = network.provisioners
            self.nodes = network.nodes
            self.networkKeys = network.networkKeys
            self.applicationKeys = network.applicationKeys
            self.groups = network.groups
            self.scenes = network.scenes
            
        case let .partial(networkKeysConfiguration,
                          applicationKeysConfiguration,
                          provisionersConfiguration,
                          nodesConfiguration,
                          groupsConfiguration,
                          scenesConfiguration):
            self.isPartial = true
            
            // Copy Network Keys.
            switch networkKeysConfiguration {
            case .all:
                self.networkKeys = network.networkKeys
            case let .some(networkKeys):
                self.networkKeys = network.networkKeys
                    .filter { networkKeys.contains($0) }
            }
            // Copy Application Keys.
            switch applicationKeysConfiguration {
            case .all:
                self.applicationKeys = network.applicationKeys
                    .boundTo(self.networkKeys)
            case let .some(applicationKeys):
                self.applicationKeys = network.applicationKeys
                    .filter { applicationKeys.contains($0) }
                    .boundTo(self.networkKeys)
            }
            // Copy Provisioners.
            switch provisionersConfiguration {
            case .all:
                // All Provisioners are copied, but some of the Nodes
                // belonging to them may get truncated. Provisioners may be
                // copied to keep the ranges.
                self.provisioners = network.provisioners
            case let .one(provisioner):
                // The exported configuration will contain only one Provisioner
                // object with the ranges prepared to be used on the importing
                // device.
                self.provisioners = [provisioner]
            case let .some(provisioners):
                self.provisioners = network.provisioners
                    .filter { provisioners.contains($0) }
            }
            let includedProvisioners = self.provisioners
            let excludedProvisioners = network.provisioners
                .filter { !includedProvisioners.contains($0) }
            // Copy Groups.
            switch groupsConfiguration {
            case .related:
                // Related Groups will be truncated later, after Nodes are chosen.
                fallthrough
            case .all:
                self.groups = network.groups
            case let .some(groups):
                self.groups = network.groups
                    .filter { groups.contains($0) }
            }
            // Copy Nodes and limit them to only those that know at least one
            // exported Network Key. From each exported Node information about
            // Application Keys, Nodes and Groups that will not be exported
            // will be cut out.
            var exportDeviceKeys = true
            switch nodesConfiguration {
            case .allWithoutDeviceKey:
                exportDeviceKeys = false
                fallthrough
            case .allWithDeviceKey:
                let networkKeys = self.networkKeys
                let applicationKeys = self.applicationKeys
                let groups = self.groups
                self.nodes = network.nodes
                    .filter { node in node.networkKeys.contains { networkKeys.contains($0) } }
                    .filter { node in !excludedProvisioners.contains { $0.node == node } }
                    .map {
                        Node(copy: $0, withDeviceKey: exportDeviceKeys,
                             andTruncateTo: networkKeys, applicationKeys: applicationKeys,
                             nodes: network.nodes, groups: groups)
                    }
            case let .some(withDeviceKey: full, andSomeWithout: partial):
                let networkKeys = self.networkKeys
                let applicationKeys = self.applicationKeys
                let groups = self.groups
                let exportedNodes = network.nodes
                    .filter { full.contains($0) || partial.contains($0) }
                    .filter { node in node.networkKeys.contains { networkKeys.contains($0) } }
                    .filter { node in !excludedProvisioners.contains { $0.node == node } }
                self.nodes = exportedNodes
                    .filter { full.contains($0) }
                    .map {
                        Node(copy: $0, withDeviceKey: true,
                             andTruncateTo: networkKeys, applicationKeys: applicationKeys,
                             nodes: exportedNodes, groups: groups)
                    } + exportedNodes
                    .filter { partial.contains($0) && !full.contains($0) }
                    .map {
                        Node(copy: $0, withDeviceKey: false,
                             andTruncateTo: networkKeys, applicationKeys: applicationKeys,
                             nodes: exportedNodes, groups: groups)
                    }
            }
            // Truncate Groups to only those used by exported Nodes.
            if case .related = groupsConfiguration {
                let nodes = self.nodes
                self.groups = self.groups
                    .filter { group in
                        nodes
                            .flatMap { node in node.elements }
                            .flatMap { element in element.models }
                            .contains { model in
                                model.subscribe.contains(group.groupAddress) ||
                                model.publish?.address == group.groupAddress
                            }
                    }
            }
            // Copy Scenes.
            switch scenesConfiguration {
            case .all:
                let nodes = self.nodes
                self.scenes = network.scenes
                    .map { Scene(copy: $0, andTruncateTo: nodes) }
            case .related:
                let nodes = self.nodes
                self.scenes = network.scenes
                    .map { Scene(copy: $0, andTruncateTo: nodes) }
                    .filter { $0.isUsed }
            case let .some(scenes):
                let nodes = self.nodes
                self.scenes = network.scenes
                    .filter { scenes.contains($0) }
                    .map { Scene(copy: $0, andTruncateTo: nodes) }
            }
            self.nodes.forEach {
                $0.meshNetwork = self
            }
        }
    }
    
    internal func copy(using configuration: ExportConfiguration) -> MeshNetwork {
        if case .full = configuration {
            return self
        } else {
            return MeshNetwork(copy: self, using: configuration)
        }
    }
    
    // MARK: - Codable
    
    /// Coding keys used to export / import Mesh Network.
    enum CodingKeys: String, CodingKey {
        case schema          = "$schema"
        case id
        case version
        case uuid            = "meshUUID"
        case isPartial       = "partial"
        case meshName
        case timestamp
        case provisioners
        case networkKeys     = "netKeys"
        case applicationKeys = "appKeys"
        case nodes
        case groups
        case scenes
        case networkExclusions
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Schema, ID and version are not validated.
        // JSON parsing will fail if the imported file is not valid.
        // Future versions should be backwards compatible.
        //
        // let schema = try container.decode(String.self, forKey: .schema)
        // let id = try container.decode(String.self, forKey: .id)
        
        // In version 3.0 of this library the Mesh UUID format has changed
        // from 32-character hexadecimal String to standard UUID format (RFC 4122).
        uuid = try container.decode(UUID.self, forKey: .uuid,
                                    orConvert: MeshUUID.self, forKey: .uuid, using: { $0.uuid })
        
        isPartial = try container.decodeIfPresent(Bool.self, forKey: .isPartial) ?? false
        meshName = try container.decode(String.self, forKey: .meshName)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        provisioners = try container.decode([Provisioner].self, forKey: .provisioners)
        guard !provisioners.isEmpty else {
            throw DecodingError.dataCorruptedError(forKey: .provisioners, in: container,
                                                   debugDescription: "At least one provisioner is required.")
        }
        networkKeys = try container.decode([NetworkKey].self, forKey: .networkKeys)
        guard !networkKeys.isEmpty else {
            throw DecodingError.dataCorruptedError(forKey: .networkKeys, in: container,
                                                   debugDescription: "At least one network key is required.")
        }
        applicationKeys = try container.decode([ApplicationKey].self, forKey: .applicationKeys)
        let ns = try container.decode([Node].self, forKey: .nodes)
        guard isPartial || !ns.contains(where: { $0.deviceKey == nil }) else {
            throw DecodingError.dataCorruptedError(forKey: .isPartial, in: container,
                                                   debugDescription: "Device Key cannot be empty in non-partial configuration.")
        }
        nodes = ns
        // Groups are mandatory, but one of the Android versions didn't export empty
        // list to JSON, so it may happen that Groups are `nil`.
        groups = try container.decodeIfPresent([Group].self, forKey: .groups) ?? []
        networkExclusions = try container.decodeIfPresent([ExclusionList].self, forKey: .networkExclusions)
        // Scenes are mandatory, but previous version of the library did support it,
        // so JSON files generated with such versions won't have "scenes" tag.
        scenes = try container.decodeIfPresent([Scene].self, forKey: .scenes) ?? []
        // The IV Index is not a shared in the JSON, as it may change.
        // The value will be obtained from the Secure Network beacon moment after
        // connecting to a Proxy node.
        ivIndex        = IvIndex()
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
        scenes.forEach {
            $0.meshNetwork = self
        }
        // Heartbeat publications and subscriptions are disabled when mesh
        // network is loaded.
        localProvisioner?.node?.heartbeatPublication = nil
        localProvisioner?.node?.heartbeatSubscription = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        let schema = "http://json-schema.org/draft-04/schema#"
        let id = "https://www.bluetooth.com/specifications/specs/mesh-cdb-1-0-1-schema.json#"
        let version = "1.0.1"
        
        var container = encoder.container(keyedBy: CodingKeys.self)        
        try container.encode(schema, forKey: .schema)
        try container.encode(id, forKey: .id)
        try container.encode(version, forKey: .version)
        
        try container.encode(uuid, forKey: .uuid)
        try container.encode(isPartial, forKey: .isPartial)
        try container.encode(meshName, forKey: .meshName)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(provisioners, forKey: .provisioners)
        try container.encode(networkKeys, forKey: .networkKeys)
        try container.encode(applicationKeys, forKey: .applicationKeys)
        try container.encode(nodes, forKey: .nodes)
        try container.encode(groups, forKey: .groups)
        try container.encode(scenes, forKey: .scenes)
        try container.encodeIfPresent(networkExclusions, forKey: .networkExclusions)
    }
    
}

// MARK: - Internal MeshNetwork API

extension MeshNetwork {
    
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
            
            // Remove Unicast Addresses of all Node's Elements from Scenes.
            scenes.forEach { scene in
                scene.remove(node: node)
            }
            // When a Node is removed from the network, the Unicast Addresses
            // it used to use cannot be assigned to another Node until the
            // IV Index is incremented by 2 (which effectively resets all Sequence
            // number counters on all Nodes).
            networkExclusions = networkExclusions ?? []
            networkExclusions!.append(node, forIvIndex: ivIndex)
            
            // As the Node is no longer part of the mesh network, remove
            // the reference to it.
            node.meshNetwork = nil
            timestamp = Date()
            
            // The stored SeqAuth value cannot be removed, as that could
            // lead to accepting repeated messages.
            /*
            // Forget the last sequence number for the device.
            let meshUuid = self.uuid
            if let defaults = UserDefaults(suiteName: meshUuid.uuidString) {
                defaults.removeSeqAuthValues(of: node)
            }
            */
        }
    }
    
    /// Adds the given Network Key to the network.
    ///
    /// - parameter key: The new Network Key to be added.
    func add(networkKey key: NetworkKey) {
        networkKeys.append(key)
        timestamp = Date()
        
        // Make the local Provisioner aware of the new key.
        localProvisioner?.node?.add(networkKey: key)
    }
    
    /// Adds the given Application Key to the network.
    ///
    /// - parameter key: The new Application Key to be added.
    func add(applicationKey key: ApplicationKey) {
        key.meshNetwork = self
        applicationKeys.append(key)
        timestamp = Date()
        
        // Make the local Provisioner aware of the new key.
        localProvisioner?.node?.add(applicationKey: key)
    }
    
    /// Adds a new Scene to the network.
    ///
    /// If the mesh network already contains a Scene with the same number,
    /// this method throws an error.
    ///
    /// - parameter scene: The Scene to be added.
    func add(scene: Scene) {
        scene.meshNetwork = self
        scenes.append(scene)
        timestamp = Date()
    }
    
}
