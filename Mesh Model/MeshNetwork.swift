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
    
    /// The last time the Provisioner database has been modified.
    public internal(set) var timestamp: Date
    /// Random 128-bit UUID allows differentiation among multiple mesh networks.
    public let meshUUID: MeshUUID
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
    }
    
    internal init(name: String, uuid: UUID = UUID()) {
        meshUUID        = MeshUUID(uuid)
        meshName        = name
        timestamp       = Date()
        provisioners    = []
        networkKeys     = []
        applicationKeys = []
    }
    
    /// Adds the provisioner.
    ///
    /// - parameter provisioner: The provisioner to be added.
    /// - throws: MeshModelError - if provisioner has allocated invalid ranges
    ///           or ranges overlapping with an existing Provisioner.
    public func add(provisioner: Provisioner) throws {
        // Validation
        if !provisioner.isValid() {
            throw MeshModelError.provisionerRangesNotAllocated
        }
        
        for other in provisioners {
            if provisioner.hasOverlappingRanges(with: other) {
                throw MeshModelError.overlappingProvisionerRanges
            }
        }
    }
}
