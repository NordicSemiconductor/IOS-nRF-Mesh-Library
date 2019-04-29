//
//  NetworkKey.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

public class NetworkKey: Key, Codable {
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
    
    internal init(name: String, index: KeyIndex, key: Data) throws {
        guard index.isValidKeyIndex else {
            throw MeshModelError.keyIndexOutOfRange
        }
        self.name        = name
        self.index       = index
        self.key         = key
        self.minSecurity = .high
        self.timestamp   = Date()
    }
    
}

// MARK: - Public API

public extension NetworkKey {
    
    /// Returns whether the Network Key is the Primary Network Key.
    /// The Primary key is the one which Key Index is equal to 0.
    ///
    /// A Primary Network Key may not be removed from the mesh network.
    var isPrimary: Bool {
        return index == 0
    }
    
    /// Return whether the Network Key is used in the given mesh network.
    ///
    /// A Network Key must be added to Network Keys array of the network
    /// and be either a Primary Key, a key known to at least one node,
    /// or bound to an existing Application Key to be used by it.
    ///
    /// An used Network Key may not be removed from the network.
    ///
    /// - parameter meshNetwork: The mesh network to look the key in.
    /// - returns: `True` if the key is used in the given network,
    ///            `false` otherwise.
    func isUsed(in meshNetwork: MeshNetwork) -> Bool {
        return meshNetwork.networkKeys.contains(self) &&
            (
                // Primary Network Key.
                isPrimary ||
                // Network Key known by at least one node.
                meshNetwork.nodes.knows(networkKey: self) ||
                // Network Key bound to an Application Key.
                meshNetwork.applicationKeys.contains(keyBoundTo: self)
            )
    }
    
}

// MARK: - Operators

extension NetworkKey: Equatable {
    
    public static func == (lhs: NetworkKey, rhs: NetworkKey) -> Bool {
        return lhs.index == rhs.index
    }
    
    public static func != (lhs: NetworkKey, rhs: NetworkKey) -> Bool {
        return lhs.index != rhs.index
    }
    
}
