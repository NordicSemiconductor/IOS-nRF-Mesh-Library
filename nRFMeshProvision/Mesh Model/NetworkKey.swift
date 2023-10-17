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

internal struct NetworkKeyDerivatives {
    /// The Identity Key.
    let identityKey: Data!
    /// The Beacon Key.
    let beaconKey: Data!
    /// The Private Beacon Key.
    let privateBeaconKey: Data!
    /// The Encryption Key.
    let encryptionKey: Data!
    /// The Privacy Key.
    let privacyKey: Data!
    /// Network identifier.
    let nid: UInt8!
    
    init(withKey key: Data) {
        (nid, encryptionKey, privacyKey, identityKey, beaconKey, privateBeaconKey) =
            Crypto.calculateKeyDerivatives(from: key)
    }
}

/// The Network Keys are used to encrypt mesh messages on the Network Layer.
///
/// A Network Key defines a subnet within the mesh network. Knowing the Network Key
/// is required to decrypt the message, handle it, or relay. Messages can only be relayed
/// within the subnet.
///
/// Each key is identified by a ``KeyIndex``. There can be up to 4095 subnets in a
/// mesh network.
///
/// The key is 128-bit long. Cryptographic algorithms are used to derive a Network ID, the NID
/// and a set of keys used for for encrypting different types of messages:
/// * Identity Key
/// * Beacon Key
/// * Private Beacon Key
/// * Encryption Key
/// * Privacy Key
///
/// The key can be changed. Changing the Network Key is a secure way of removing
/// Nodes from a mesh network. The procedure of changing a Network Key is called
/// Key Refresh Procedure (KRP). Nodes that are not part of KRP are effectively
/// excluded from the mesh network and may no longer send messages on given subnet.
///
/// A key may be either secure or insecure. A key is considered secure if all Nodes
/// that know this key have been provisioned in a secure way, that is using Out-Of-Band
/// Public Key. Any other way of provisioning devices makes the Network Key insecure.
public class NetworkKey: Key, Codable {
    /// The timestamp represents the last time the phase property has been
    /// updated.
    public private(set) var timestamp: Date
    /// UTF-8 string, which should be a human readable name of the mesh subnet
    /// associated with this network key.
    public var name: String
    /// Index of this Network Key, in range from 0 through to 4095.
    public internal(set) var index: KeyIndex
    /// Key Refresh phase.
    public internal(set) var phase: KeyRefreshPhase = .normalOperation {
        didSet {
            timestamp = Date()
        }
    }
    /// 128-bit Network Key.
    public internal(set) var key: Data {
        willSet {
            oldKey = key
            oldNetworkId = networkId
            oldKeys = keys
        }
        didSet {
            phase = .keyDistribution
            regenerateKeyDerivatives()
        }
    }
    /// The old Network Key is present when the phase property has a different
    /// value than ``KeyRefreshPhase/normalOperation``, such as when a Key Refresh
    /// procedure is in progress.
    public internal(set) var oldKey: Data? {
        didSet {
            if oldKey == nil {
                oldNetworkId = nil
                oldKeys = nil
                phase = .normalOperation
            }
        }
    }
    /// Minimum security level for a subnet associated with this Network Key.
    ///
    /// If all Nodes on the subnet associated with this network key have been
    /// provisioned using the Secure Provisioning procedure, then
    /// the value of this property for the subnet is set to ``Security/secure``;
    /// otherwise the value is set to ``Security/insecure`` and the subnet
    /// is considered less secure.
    public private(set) var minSecurity: Security
    
    /// The Network ID derived from this Network Key. This identifier
    /// is public information.
    public private(set) var networkId: Data!
    /// The Network ID derived from the old Network Key. This identifier
    /// is public information. It is set when ``NetworkKey/oldKey`` is set.
    public private(set) var oldNetworkId: Data?
    /// Network Key derivatives.
    internal private(set) var keys: NetworkKeyDerivatives!
    /// Network Key derivatives.
    internal private(set) var oldKeys: NetworkKeyDerivatives?
    /// Returns the key set that should be used for encrypting outgoing packets.
    internal var transmitKeys: NetworkKeyDerivatives {
        if case .keyDistribution = phase, let oldKeys = oldKeys {
            return oldKeys
        }
        return keys
    }
    
    internal init(name: String, index: KeyIndex, key: Data) throws {
        guard key.count == 16 else {
            throw MeshNetworkError.invalidKey
        }
        guard index.isValidKeyIndex else {
            throw MeshNetworkError.keyIndexOutOfRange
        }
        self.name        = name
        self.index       = index
        self.key         = key
        // Initially, a Network Key is considered secure, as there are no Nodes
        // that know it other than the Provisioner's one.
        self.minSecurity = .secure
        self.timestamp   = Date()
        
        regenerateKeyDerivatives()
    }
    
    /// Creates the primary Network Key for a mesh network.
    internal convenience init() {
        try! self.init(name: "Primary Network Key", index: 0, key: Data.random128BitKey())
    }
    
    private func regenerateKeyDerivatives() {
        // Calculate Network ID.
        networkId = Crypto.calculateNetworkId(from: key)
        // Calculate other keys.
        keys = NetworkKeyDerivatives(withKey: key)
        
        // When the Network Key is imported from JSON, old key derivatives must
        // be calculated.
        if let oldKey = oldKey, oldNetworkId == nil {
            // Calculate Network ID.
            oldNetworkId = Crypto.calculateNetworkId(from: oldKey)
            // Calculate other keys.
            oldKeys = NetworkKeyDerivatives(withKey: oldKey)
        }
    }
    
    // MARK: - Codable
    
    /// Coding keys used to export / import Network Keys.
    enum CodingKeys: String, CodingKey {
        case name
        case index
        case key
        case oldKey
        case phase
        case minSecurity
        case timestamp
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        index = try container.decode(KeyIndex.self, forKey: .index)
        guard index.isValidKeyIndex else {
            throw DecodingError.dataCorruptedError(forKey: .index, in: container,
                                                   debugDescription: "Key Index must be in range 0-4095.")
        }
        let keyHex = try container.decode(String.self, forKey: .key)
        key = Data(hex: keyHex)
        guard !key.isEmpty else {
            throw DecodingError.dataCorruptedError(forKey: .key, in: container,
                                                   debugDescription: "Key must be 32-character hexadecimal string.")
        }
        networkId = Crypto.calculateNetworkId(from: key)
        if let oldKeyHex = try container.decodeIfPresent(String.self, forKey: .oldKey) {
            oldKey = Data(hex: oldKeyHex)
            guard !oldKey!.isEmpty else {
                throw DecodingError.dataCorruptedError(forKey: .oldKey, in: container,
                                                       debugDescription: "Old key must be 32-character hexadecimal string.")
            }
        }
        phase = try container.decode(KeyRefreshPhase.self, forKey: .phase)
        minSecurity = try container.decode(Security.self, forKey: .minSecurity)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        regenerateKeyDerivatives()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(index, forKey: .index)
        try container.encode(key.hex, forKey: .key)
        try container.encodeIfPresent(oldKey?.hex, forKey: .oldKey)
        try container.encode(phase, forKey: .phase)
        try container.encode(minSecurity, forKey: .minSecurity)
        try container.encode(timestamp, forKey: .timestamp)
    }
}

public extension NetworkKey {
    
    /// This method lowers the minimum security level of the Network Key to
    /// ``Security/insecure``.
    ///
    /// - seeAlso: ``Security``
    /// - seeAlso: ``NetworkKey/minSecurity``
    func lowerSecurity() {
        minSecurity = .insecure
    }
    
}

// MARK: - Operators

extension NetworkKey: Equatable {
    
    public static func == (lhs: NetworkKey, rhs: NetworkKey) -> Bool {
        return lhs.index == rhs.index
            && lhs.phase == rhs.phase
            && lhs.key == rhs.key
            && lhs.oldKey == rhs.oldKey
            && lhs.name == rhs.name
    }
    
}

extension NetworkKey: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        if phase != .normalOperation {
            return "\(name) (index: \(index), phase: \(phase))"
        }
        return "\(name) (index: \(index))"
    }
    
}
