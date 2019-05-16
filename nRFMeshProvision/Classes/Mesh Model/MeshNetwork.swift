//
//  MeshNetwork.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 19/03/2019.
//

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
    /// The IV Index.
    internal var ivIndex: IvIndex
    
    internal init(name: String, uuid: UUID = UUID()) {
        schema          = "http://json-schema.org/draft-04/schema#"
        id              = "TBD"
        version         = "1.0.0"
        meshUUID        = MeshUUID(uuid)
        meshName        = name
        timestamp       = Date()
        provisioners    = []
        networkKeys     = []
        applicationKeys = []
        nodes           = []
        ivIndex         = IvIndex()
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
        // The IV Index is not a shared in the JSON, as it may change.
        // The value may be obtained from the Security Beacon.
        ivIndex = IvIndex()
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
    
    func add(node: Node) {
        nodes.append(node)
    }
    
}
