//
//  NetworkKey.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

internal struct NetworkKeyDerivaties {
    /// The Identity Key.
    let identityKey: Data!
    /// The Beacon Key.
    let beaconKey: Data!
    /// The Encryption Key.
    let encryptionKey: Data!
    /// The Privacy Key.
    let privacyKey: Data!
    
    init(withKey key: Data, using helper: OpenSSLHelper) {
        // Calculate Identity Key and Beacon Key.
        let P = Data([0x69, 0x64, 0x31, 0x32, 0x38, 0x01]) // "id128" || 0x01
        let saltIK = helper.calculateSalt("nkik".data(using: .ascii)!)!
        identityKey = helper.calculateK1(withN: key, salt: saltIK, andP: P)
        let saltBK = helper.calculateSalt("nkbk".data(using: .ascii)!)!
        beaconKey = helper.calculateK1(withN: key, salt: saltBK, andP: P)
        // Calculate Encryption Key and Privacy Key.
        let hash = helper.calculateK2(withN: key, andP: Data([0x00]))!
        // NID was already generated in Network Key below and is ignored here.
        encryptionKey = hash.subdata(in: 1..<17)
        privacyKey = hash.subdata(in: 17..<33)
    }
}

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
    public internal(set) var key: Data {
        willSet {
            oldKey = key
            oldNetworkId = networkId
            oldNid = nid
            oldKeys = keys
        }
        didSet {
            phase = .distributingKeys
            regenerateKeyDerivaties()
        }
    }
    /// The old Network Key is present when the phase property has a non-zero
    /// value, such as when a Key Refresh procedure is in progress.
    public internal(set) var oldKey: Data? {
        didSet {
            if oldKey == nil {
                oldNetworkId = nil
                oldNid = nil
                oldKeys = nil
                phase = .normalOperation
            }
        }
    }
    /// Minimum security level for a subnet associated with this network key.
    /// If all nodes on the subnet associated with this network key have been
    /// provisioned using network the Secure Provisioning procedure, then
    /// the value of this property for the subnet is set to .high; otherwise
    /// the value is set to .low and the subnet is considered less secure.
    public internal(set) var minSecurity: Security
    
    /// The Network ID derived from this Network Key. This identifier
    /// is public information.
    public internal(set) var networkId: Data!
    /// The Network ID derived from the old Network Key. This identifier
    /// is public information. It is set when `oldKey` is set.
    public internal(set) var oldNetworkId: Data?
    /// The IV Index for this subnetwork.
    internal var ivIndex: IvIndex
    /// Network Key derivaties.
    internal var keys: NetworkKeyDerivaties!
    /// Network Key derivaties.
    internal var oldKeys: NetworkKeyDerivaties?
    /// Returns the key set that should be used for encrypting outgoing packets.
    internal var transmitKeys: NetworkKeyDerivaties {
        if case .distributingKeys = phase {
            return oldKeys!
        }
        return keys
    }
    /// Network identifier.
    internal var nid: UInt8!
    /// Network identifier derived from the old key.
    internal var oldNid: UInt8?
    
    internal init(name: String, index: KeyIndex, key: Data) throws {
        guard index.isValidKeyIndex else {
            throw MeshNetworkError.keyIndexOutOfRange
        }
        self.name        = name
        self.index       = index
        self.key         = key
        self.minSecurity = .high
        self.timestamp   = Date()
        
        // The IV Index is not a shared in the JSON, as it may change.
        // The current value will be obtained from the Security Beacon.
        ivIndex = IvIndex()
        
        regenerateKeyDerivaties()
    }
    
    /// Creates the primary Network Key for a mesh network.
    internal convenience init() {
        try! self.init(name: "Primary Network Key", index: 0, key: OpenSSLHelper().generateRandom())
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
        let keyHex = try container.decode(String.self, forKey: .key)
        guard let keyData = Data(hex: keyHex) else {
            throw DecodingError.dataCorruptedError(forKey: .key, in: container,
                                                   debugDescription: "Key must be 32-character hexadecimal string")
        }
        key = keyData
        networkId = OpenSSLHelper().calculateK3(withN: key)
        if let oldKeyHex = try container.decodeIfPresent(String.self, forKey: .oldKey) {
            guard let oldKeyData = Data(hex: oldKeyHex) else {
                throw DecodingError.dataCorruptedError(forKey: .oldKey, in: container,
                                                       debugDescription: "Old key must be 32-character hexadecimal string")
            }
            oldKey = oldKeyData
        }
        phase = try container.decode(KeyRefreshPhase.self, forKey: .phase)
        minSecurity = try container.decode(Security.self, forKey: .minSecurity)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        // The IV Index is not a shared in the JSON, as it may change.
        // The current value will be obtained from the Security Beacon.
        ivIndex = IvIndex()
        
        regenerateKeyDerivaties()
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
    
    private func regenerateKeyDerivaties() {
        let helper = OpenSSLHelper()
        // Calculate Network ID.
        networkId = helper.calculateK3(withN: key)
        // Calculate NID.
        let hash = helper.calculateK2(withN: key, andP: Data([0x00]))!
        nid = hash[0] & 0x7F
        // Calculate other keys.
        keys = NetworkKeyDerivaties(withKey: key, using: helper)
        
        // When the Network Key is imported from JSON, old key derivaties must
        // be calculated.
        if let oldKey = oldKey, oldNid == nil {
            // Calculate Network ID.
            oldNetworkId = helper.calculateK3(withN: oldKey)
            // Calculate NID.
            let hash = helper.calculateK2(withN: oldKey, andP: Data([0x00]))!
            oldNid = hash[0] & 0x7F
            // Calculate other keys.
            oldKeys = NetworkKeyDerivaties(withKey: oldKey, using: helper)
        }
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

extension NetworkKey: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        if phase != .normalOperation {
            return "\(name) (index: \(index), phase: \(phase))"
        }
        return "\(name) (index: \(index))"
    }
    
}
