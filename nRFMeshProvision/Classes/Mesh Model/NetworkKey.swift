//
//  NetworkKey.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

/// The type representing Key Refresh phase.
public enum KeyRefreshPhase: Int, Codable {
    /// Phase 0: Normal Operation.
    case normalOperation  = 0
    /// Phase 1: Distributing new keys to all nodes. Nodes will transmit using
    /// old keys, but can receive using old and new keys.
    case distributingKeys = 1
    /// Phase 2: Transmitting a Secure Network beacon that signals to the network
    /// that all nodes have the new keys. The nodes will then transmit using
    /// the new keys but can receive using the old or new keys.
    case finalizing       = 2
}

/// The type representing Minimum security level for a subnet.
/// If all nodes on the subnet associated with this network key have been
/// provisioned using network the Secure Provisioning procedure, then
/// the value of this property for the subnet is set to .high; otherwise
/// the value is set to .low and the subnet is considered less secure.
public enum MinSecurity: String, Codable {
    case low    = "low"
    case high   = "high"
}

public class NetworkKey: Codable {
    /// The timestamp represents the last time the phase property has been
    /// updated.
    public internal(set) var timestamp: Date
    /// UTF-8 string, which should be a human readable name of the mesh subnet
    /// associated with this network key.
    public var name: String
    /// Index of this Network Key, in range from 0 through to 4095.
    public var index: KeyIndex {
        didSet {
            if index.isValidKeyIndex() {
                timestamp = Date()
            } else {
                 index = oldValue
            }
        }
    }
    /// Key Refresh phase.
    public var phase: KeyRefreshPhase = .normalOperation {
        didSet {
            timestamp = Date()
        }
    }
    /// 128-bit Network Key.
    public var key: Data
    /// Minimum security level for a subnet associated with this network key.
    /// If all nodes on the subnet associated with this network key have been
    /// provisioned using network the Secure Provisioning procedure, then
    /// the value of this property for the subnet is set to .high; otherwise
    /// the value is set to .low and the subnet is considered less secure.
    public var minSecurity: MinSecurity
    /// The old Network Key is present when the phase property has a non-zero
    /// value, such as when a Key Refresh procedure is in progress.
    public var oldKey: Data? = nil
    
    public init(name: String, index: KeyIndex, key: Data) {
        self.name        = name
        self.index       = index
        self.key         = key
        self.minSecurity = .high
        self.timestamp   = Date()
    }
}
