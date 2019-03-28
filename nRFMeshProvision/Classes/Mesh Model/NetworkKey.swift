//
//  NetworkKey.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

public class NetworkKey: Codable {
    /// The timestamp represents the last time the phase property has been
    /// updated.
    public internal(set) var timestamp: Date
    /// UTF-8 string, which should be a human readable name of the mesh subnet
    /// associated with this network key.
    public var name: String
    /// Index of this Network Key, in range from 0 through to 4095.
    public internal(set) var index: KeyIndex {
        didSet {
            timestamp = Date()
        }
    }
    /// Key Refresh phase.
    public internal(set) var phase: KeyRefreshPhase = .normalOperation {
        didSet {
            timestamp = Date()
        }
    }
    /// 128-bit Network Key.
    public internal(set) var key: Data
    /// Minimum security level for a subnet associated with this network key.
    /// If all nodes on the subnet associated with this network key have been
    /// provisioned using network the Secure Provisioning procedure, then
    /// the value of this property for the subnet is set to .high; otherwise
    /// the value is set to .low and the subnet is considered less secure.
    public var minSecurity: Security
    /// The old Network Key is present when the phase property has a non-zero
    /// value, such as when a Key Refresh procedure is in progress.
    public internal(set) var oldKey: Data? = nil
    
    public init(name: String, index: KeyIndex, key: Data) {
        self.name        = name
        self.index       = index
        self.key         = key
        self.minSecurity = .high
        self.timestamp   = Date()
    }
}
