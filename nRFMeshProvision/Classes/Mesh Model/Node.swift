//
//  Node.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 22/03/2019.
//

import Foundation

public class Node: Codable {

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
    public internal(set) var deviceKey: Data?
    /// The level of security for the subnet on which the node has been
    /// originally provisioner.
    public internal(set) var security: Security?
    /// An array of node network key objects that include information
    /// about the network keys known to this node.
    public internal(set) var netKeys: [NodeKey]
    /// An array of node application key objects that include information
    /// about the application keys known to this node.
    public internal(set) var appKeys: [NodeKey]
    /// The boolean value represents whether the Mesh Manager
    /// has finished configuring this node. The property is set to `true`
    /// once a Mesh Manager is done completing this node's
    /// configuration, otherwise it is set to `false`.
    public internal(set) var configComplete: Bool = false
    /// UTF-8 human-readable name of the node within the network.
    public var name: String?
    /// The 16-bit Company Identifier (CID) assigned by the Bluetooth SIG.
    /// The value of this property is obtained from node composition data.
    public var companyIdentifier: UInt16?
    /// The 16-bit vendor-assigned Product Identifier (PID).
    /// The value of this property is obtained from node composition data.
    public var productIdentifier: UInt16?
    /// The 16-bit vendor-assigned Version Identifier (VID).
    /// The value of this property is obtained from node composition data.
    public var versionIdentifier: UInt16?
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
    public internal(set) var defaultTTL: UInt8?
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
    
    private enum CodingKeys: String, CodingKey {
        case nodeUuid = "uuid"
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
        case defaultTTL
        case networkTransmit
        case relayRetransmit
        case elements
        case blacklisted
    }
    
    /// A constructor needed only for testing.
    internal init(name: String?, unicastAddress: Address, elements: UInt8) {
        self.nodeUuid = MeshUUID()
        self.name = name
        self.unicastAddress = unicastAddress
        // Default values
        self.appKeys  = []
        self.netKeys  = []
        self.elements = []
        
        for i in 0..<elements {
            self.elements.append(Element(index: i, location: .unknown))
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
        
        self.appKeys  = []
        self.netKeys  = []
        self.elements = []
    }
}

// MARK: - Public API

public extension Node {
    
    /// Number of mode's elements.
    var elementsCount: UInt16 {
        return UInt16(elements.count)
    }
    
    /// The last unicast address allocated to this node. Each node's element
    /// uses its own subsequent unicast address. The first (0th) element is identified
    /// by the node's unicast address. If there are no elements, the last unicast address
    /// is equal to the node's unicast address.
    var lastUnicastAddress: UInt16 {
        // Provisioner may not have any elements
        let allocatedAddresses = elementsCount > 0 ? elementsCount : 1
        return unicastAddress + allocatedAddresses - 1
    }

    /// Returns whether the address uses the given unicast address for one
    /// of its elements.
    ///
    /// - parameter address: Address to check.
    /// - returns: `True` if any of node's elements (or the node itself) was assigned
    ///            the given address, `false` otherwise.
    func hasAllocatedAddress(_ address: Address) -> Bool {
        return address >= unicastAddress && address <= lastUnicastAddress
    }
}
