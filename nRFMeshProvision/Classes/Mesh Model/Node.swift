//
//  Node.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 22/03/2019.
//

import Foundation

public class Node: Codable {
    internal weak var meshNetwork: MeshNetwork?

    /// The state of a network or application key distributed to a mesh
    /// node by a Mesh Manager.
    public class NodeKey: Codable {
        /// The Key index for this network key.
        public internal(set) var index: KeyIndex
        /// This flag contains value set to `false`, unless a Key Refresh
        /// procedure is in progress and the network has been successfully
        /// updated.
        public internal(set) var updated: Bool
        
        internal init(index: KeyIndex, updated: Bool) {
            self.index   = index
            self.updated = updated
        }
        
        internal init(of key: Key) {
            self.index   = key.index
            self.updated = false
        }
    }
    
    /// The object represents parameters of the transmissions of network
    /// layer messages originating from a mesh node.
    public class NetworkTransmit: Codable {
        /// Number of retransmissions for relay messages.
        /// The value is in range from 1 to 8.
        public internal(set) var count: UInt8
        /// The interval (in milliseconds) between retransmissions.
        public internal(set) var interval: UInt16
        
        internal init(transmissionCount: UInt8, intervalSteps: UInt16) {
            // The number of times that packet is transmitted for each
            // packet that is relayed is Ttransmit Count + 1.
            self.count    = transmissionCount + 1
            // Interval is in 10 ms steps.
            self.interval = intervalSteps * 10 // ms
        }
    }
    
    /// The object represents parameters of the retransmissions of network
    /// layer messages relayed by a mesh node.
    public class RelayRetransmit: Codable {
        /// Number of retransmissions for network messages.
        /// The value is in range from 1 to 8.
        public internal(set) var count: UInt8
        /// The interval (in milliseconds) between retransmissions.
        public internal(set) var interval: UInt16
        
        internal init(relayRetransmitCount: UInt8, intervalSteps: UInt16) {
            // The number of times that packet is retransmitted for each
            // packet that is relayed is Relay Retransmit Count + 1.
            self.count    = relayRetransmitCount + 1
            // Interval is in 10 ms steps.
            self.interval = intervalSteps * 10 // ms
        }
    }
    
    /// Unique node identifier.
    internal let nodeUuid: MeshUUID
    /// Random 128-bit UUID allows differentiation among multiple mesh networks.
    public var uuid: UUID {
        return nodeUuid.uuid
    }
    /// Primary unicast address of the node.
    public internal(set) var unicastAddress: Address
    /// 128-bit device key for this node.
    public internal(set) var deviceKey: Data
    /// The level of security for the subnet on which the node has been
    /// originally provisioner.
    public internal(set) var security: Security
    /// An array of node network key objects that include information
    /// about the network keys known to this node.
    internal var netKeys: [NodeKey]
    /// An array of node application key objects that include information
    /// about the application keys known to this node.
    internal var appKeys: [NodeKey]
    /// The boolean value represents whether the Mesh Manager
    /// has finished configuring this node. The property is set to `true`
    /// once a Mesh Manager is done completing this node's
    /// configuration, otherwise it is set to `false`.
    public var configComplete: Bool = false
    /// UTF-8 human-readable name of the node within the network.
    public var name: String?
    /// The 16-bit Company Identifier (CID) assigned by the Bluetooth SIG.
    /// The value of this property is obtained from node composition data.
    public internal(set) var companyIdentifier: UInt16?
    /// The 16-bit vendor-assigned Product Identifier (PID).
    /// The value of this property is obtained from node composition data.
    public internal(set) var productIdentifier: UInt16?
    /// The 16-bit vendor-assigned Version Identifier (VID).
    /// The value of this property is obtained from node composition data.
    public internal(set) var versionIdentifier: UInt16?
    /// The minimum number of Replay Protection List (RPL) entries for this
    /// node. The value of this property is obtained from node composition
    /// data.
    public internal(set) var minimumNumberOfReplayProtectionList: UInt16?
    /// Node's features. See `NodeFeatures` for details.
    public internal(set) var features: NodeFeatures?
    /// This flag represents whether or not the node is configured to send
    /// Secure Network messages.
    public internal(set) var secureNetworkBeacon: Bool?
    /// The default Time To Leave (TTL) value used when sending messages.
    internal var ttl: UInt8?
    /// The default Time To Leave (TTL) value used when sending messages.
    /// The TTL may only be set for a Provisioner's Node, or for a Node
    /// that has not been added to a mesh network.
    ///
    /// Use `ConfigDefaultTtlGet` and `ConfigDefaultTtlSet` messages to read
    /// or set the default TTL value.
    public var defaultTTL: UInt8? {
        set {
            if let meshNetwork = meshNetwork, !meshNetwork.hasProvisioner(with: uuid) {
                return
            }
            ttl = newValue
        }
        get {
            return ttl
        }
    }
    /// The object represents parameters of the transmissions of network
    /// layer messages originating from a mesh node.
    public internal(set) var networkTransmit: NetworkTransmit?
    /// The object represents parameters of the retransmissions of network
    /// layer messages relayed by a mesh node.
    public internal(set) var relayRetransmit: RelayRetransmit?
    /// An array of node's elements.
    public internal(set) var elements: [Element]
    /// The flag is set to `true` when the Node is in the process of being
    /// deleted and is excluded from the new network key distribution
    /// during the key refresh procedure; otherwise is set to `false`.
    public internal(set) var blacklisted: Bool = false
    
    /// Returns list of Network Keys known to this Node.
    public var networkKeys: [NetworkKey] {
        return meshNetwork?.networkKeys.filter { knows(networkKey: $0) } ?? []
    }
    /// Returns list of Application Keys known to this Node.
    public var applicationKeys: [ApplicationKey] {
        return meshNetwork?.applicationKeys.filter { knows(applicationKey: $0) } ?? []
    }
    
    /// A constructor needed only for testing.
    internal init(name: String?, unicastAddress: Address, elements: UInt8) {
        self.nodeUuid = MeshUUID()
        self.name = name
        self.unicastAddress = unicastAddress
        self.deviceKey = Data.random128BitKey()
        self.security = .high
        // Default values
        self.appKeys  = []
        self.netKeys  = []
        self.elements = []
        
        for _ in 0..<elements {
            add(element: Element(location: .unknown))
        }
    }
    
    /// Initializes the Provisioner's node.
    /// The Provisioner's node has the same name and node UUID as the Provisioner.
    ///
    /// - parameter provisioner: The Provisioner for which the node is added.
    /// - parameter address:     The unicast address to be assigned to the Node.
    internal init(for provisioner: Provisioner, withAddress address: Address) {
        self.nodeUuid = provisioner.provisionerUuid
        self.name     = provisioner.provisionerName
        self.unicastAddress = address
        self.deviceKey = Data.random128BitKey()
        self.security = .high
        self.companyIdentifier = 0x004C // Apple Inc.
        // A flag that there is no need to perform configuration of
        // a Provisioner's node.
        self.configComplete = true
        // This Provisioner does not support any of those features.
        self.features = NodeFeatures()
        
        // Keys will ba added later.
        self.appKeys  = []
        self.netKeys  = []
        // Initialize elements.
        self.elements = []
        
        // Add the primary Element.
        let element = Element(location: .unknown)
        element.name = "Primary Element"
        // Those 2 models are required for all nodes.
        element.add(model: .configurationServer)
        element.add(model: .healthServer)
        // Configuration Client model is added, as this is a Provisioner's node.
        element.add(model: .configurationClient)
        add(element: element)
    }
    
    internal init(for unprovisionedDevice: UnprovisionedDevice,
                  with n: UInt8, elementsDeviceKey deviceKey: Data,
                  andAssignedNetworkKey networkKey: NetworkKey, andAddress address: Address) {
        self.nodeUuid = MeshUUID(unprovisionedDevice.uuid)
        self.name     = unprovisionedDevice.name
        self.unicastAddress = address
        self.deviceKey = deviceKey
        self.security = .high
        // Composition Data were not obtained.
        self.configComplete = false
        
        // The node has been provisioned with one Network Key.
        self.netKeys  = [NodeKey(index: networkKey.index, updated: false)]
        self.appKeys  = []
        // Elements will be queried with Composition Data.
        self.elements = []
        for _ in 0..<n {
            add(element: Element(location: .unknown))
        }
    }
    
    /// Creates a low security Node with given Device Key, Network Key and Unicast Address.
    /// Usually, a Node is added to a network during provisioning. However, for debug
    /// purposes, or to add an already provisioned Node, one can use this method.
    /// A Node created this way will have security set to `.low`.
    ///
    /// Use `meshNetwork.add(node: Node)` to add the Node. Other parameters must be
    /// read from the Node using Configuration messages.
    ///
    /// - parameter name: Optional Node name.
    /// - parameter n: Number of Elements. Elements must be read using
    ///                `ConfigCompositionDataGet` message.
    /// - parameter deviceKey: The 128-bit Device Key.
    /// - parameter networkKey: The Network Key known to this device.
    /// - parameter address: The device Unicast Address.
    public init?(lowSecurityNode name: String?, with n: UInt, elementsDeviceKey deviceKey: Data,
                andAssignedNetworkKey networkKey: NetworkKey, andAddress address: Address) {
        guard address.isUnicast else {
            return nil
        }
        self.nodeUuid = MeshUUID()
        self.name     = name
        self.unicastAddress = address
        self.deviceKey = deviceKey
        self.security = .low
        // Composition Data were not obtained.
        self.configComplete = false
        
        self.netKeys  = [NodeKey(index: networkKey.index, updated: false)]
        self.appKeys  = []
        // Elements will be queried with Composition Data.
        // But we have to mark how many Elements there will be to validate the
        // Unicast address when adding a Node.
        self.elements = []
        for _ in 0..<n {
            add(element: Element(location: .unknown))
        }
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case nodeUuid = "UUID"
        case unicastAddress
        case deviceKey
        case security
        case netKeys
        case appKeys
        case configComplete
        case name
        case companyIdentifier = "cid"
        case productIdentifier = "pid"
        case versionIdentifier = "vid"
        case minimumNumberOfReplayProtectionList = "crpl"
        case features
        case secureNetworkBeacon
        case ttl = "defaultTTL"
        case networkTransmit
        case relayRetransmit
        case elements
        case blacklisted
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let unicastAddressAsString = try container.decode(String.self, forKey: .unicastAddress)
        guard let unicastAddress = Address(hex: unicastAddressAsString) else {
            throw DecodingError.dataCorruptedError(forKey: .unicastAddress, in: container,
                                                   debugDescription: "Address must be 4-character hexadecimal string")
        }
        let keyHex = try container.decode(String.self, forKey: .deviceKey)
        guard let keyData = Data(hex: keyHex) else {
            throw DecodingError.dataCorruptedError(forKey: .deviceKey, in: container,
                                                   debugDescription: "Device Key must be 32-character hexadecimal string")
        }
        self.nodeUuid = try container.decode(MeshUUID.self, forKey: .nodeUuid)
        self.unicastAddress = unicastAddress
        self.deviceKey = keyData
        self.security = try container.decode(Security.self, forKey: .security)
        self.netKeys = try container.decode([NodeKey].self, forKey: .netKeys)
        self.appKeys = try container.decode([NodeKey].self, forKey: .appKeys)
        self.configComplete = try container.decode(Bool.self, forKey: .configComplete)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        if let companyIdentifierAsString = try container.decodeIfPresent(String.self, forKey: .companyIdentifier) {
            guard let companyIdentifier = UInt16(hex: companyIdentifierAsString) else {
                throw DecodingError.dataCorruptedError(forKey: .companyIdentifier, in: container,
                                                       debugDescription: "Company Identifier must be 4-character hexadecimal string")
            }
            self.companyIdentifier = companyIdentifier
        }
        if let companyIdentifierAsString = try container.decodeIfPresent(String.self, forKey: .companyIdentifier) {
            guard let companyIdentifier = UInt16(hex: companyIdentifierAsString) else {
                throw DecodingError.dataCorruptedError(forKey: .companyIdentifier, in: container,
                                                       debugDescription: "Company Identifier must be 4-character hexadecimal string")
            }
            self.companyIdentifier = companyIdentifier
        }
        if let productIdentifierAsString = try container.decodeIfPresent(String.self, forKey: .productIdentifier) {
            guard let productIdentifier = UInt16(hex: productIdentifierAsString) else {
                throw DecodingError.dataCorruptedError(forKey: .productIdentifier, in: container,
                                                       debugDescription: "Product Identifier must be 4-character hexadecimal string")
            }
            self.productIdentifier = productIdentifier
        }
        if let versionIdentifierAsString = try container.decodeIfPresent(String.self, forKey: .versionIdentifier) {
            guard let versionIdentifier = UInt16(hex: versionIdentifierAsString) else {
                throw DecodingError.dataCorruptedError(forKey: .versionIdentifier, in: container,
                                                       debugDescription: "Version Identifier must be 4-character hexadecimal string")
            }
            self.versionIdentifier = versionIdentifier
        }
        if let crplAsString = try container.decodeIfPresent(String.self, forKey: .minimumNumberOfReplayProtectionList) {
            guard let crpl = UInt16(hex: crplAsString) else {
                throw DecodingError.dataCorruptedError(forKey: .minimumNumberOfReplayProtectionList, in: container,
                                                       debugDescription: "CRPL must be 4-character hexadecimal string")
            }
            self.minimumNumberOfReplayProtectionList = crpl
        }
        self.features = try container.decodeIfPresent(NodeFeatures.self, forKey: .features)
        self.secureNetworkBeacon = try container.decodeIfPresent(Bool.self, forKey: .secureNetworkBeacon)
        self.ttl = try container.decodeIfPresent(UInt8.self, forKey: .ttl)
        self.networkTransmit = try container.decodeIfPresent(NetworkTransmit.self, forKey: .networkTransmit)
        self.relayRetransmit = try container.decodeIfPresent(RelayRetransmit.self, forKey: .relayRetransmit)
        self.elements = try container.decode([Element].self, forKey: .elements)
        self.blacklisted = try container.decode(Bool.self, forKey: .blacklisted)
        
        elements.forEach {
            $0.parentNode = self
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nodeUuid, forKey: .nodeUuid)
        try container.encode(unicastAddress.hex, forKey: .unicastAddress) // <- HEX value encoded
        try container.encode(deviceKey.hex, forKey: .deviceKey) // <- HEX value encoded
        try container.encode(security, forKey: .security)
        try container.encode(netKeys, forKey: .netKeys)
        try container.encode(appKeys, forKey: .appKeys)
        try container.encode(configComplete, forKey: .configComplete)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(companyIdentifier?.hex, forKey: .companyIdentifier)
        try container.encodeIfPresent(productIdentifier?.hex, forKey: .productIdentifier)
        try container.encodeIfPresent(versionIdentifier?.hex, forKey: .versionIdentifier)
        try container.encodeIfPresent(minimumNumberOfReplayProtectionList?.hex, forKey: .minimumNumberOfReplayProtectionList)
        try container.encodeIfPresent(features, forKey: .features)
        try container.encodeIfPresent(secureNetworkBeacon, forKey: .secureNetworkBeacon)
        try container.encodeIfPresent(ttl, forKey: .ttl)
        try container.encodeIfPresent(networkTransmit, forKey: .networkTransmit)
        try container.encodeIfPresent(relayRetransmit, forKey: .relayRetransmit)
        try container.encode(elements, forKey: .elements)
        try container.encode(blacklisted, forKey: .blacklisted)
    }
}

internal extension Node {
    
    /// Adds the given Element to the Node.
    ///
    /// - parameter element: The Element to be added.
    func add(element: Element) {
        let index = UInt8(elements.count)
        elements.append(element)
        element.parentNode = self
        element.index = index
    }
    
    /// Adds given list of Elements to the Node.
    ///
    /// - parameter element: The list of Elements to be added.
    func add(elements: [Element]) {
        elements.forEach {
            add(element: $0)
        }
    }
    
}
