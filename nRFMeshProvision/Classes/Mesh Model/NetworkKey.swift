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
    public internal(set) var minSecurity: Security
    /// The old Network Key is present when the phase property has a non-zero
    /// value, such as when a Key Refresh procedure is in progress.
    public internal(set) var oldKey: Data? = nil
    
    /// The Network ID derived from this Network Key. This identifier
    /// is public information.
    public internal(set) var networkId: Data
    /// The Identity Key.
    internal var identityKey: Data
    /// The Beacon Key.
    internal var beaconKey: Data
    /// The Encryption Key.
    internal var encryptionKey: Data
    /// The Privacy Key.
    internal var privacyKey: Data
    /// Network identifier.
    internal var nid: UInt8
    
    internal init(name: String, index: KeyIndex, key: Data) throws {
        guard index.isValidKeyIndex else {
            throw MeshModelError.keyIndexOutOfRange
        }
        self.name        = name
        self.index       = index
        self.key         = key
        self.minSecurity = .high
        self.timestamp   = Date()
        
        let helper = OpenSSLHelper()
        // Calculate Network ID.
        networkId = helper.calculateK3(withN: key)
        // Calculate Identity Key and Beacon Key.
        let P = Data([0x69, 0x64, 0x31, 0x32, 0x38, 0x01]) // "id128" || 0x01
        let saltIK = helper.calculateSalt("nkik".data(using: .ascii)!)!
        identityKey = helper.calculateK1(withN: key, salt: saltIK, andP: P)
        let saltBK = helper.calculateSalt("nkbk".data(using: .ascii)!)!
        beaconKey = helper.calculateK1(withN: key, salt: saltBK, andP: P)
        // Calculate NIC, Encryption Key and Privacy Key.
        let hash = helper.calculateK2(withN: key, andP: Data([0x00]))!
        nid = hash[0] & 0x7F
        encryptionKey = hash.subdata(in: 1..<17)
        privacyKey = hash.subdata(in: 17..<33)
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
        
        let helper = OpenSSLHelper()
        // Calculate Network ID.
        networkId = helper.calculateK3(withN: key)
        // Calculate Identity Key and Beacon Key.
        let P = Data([0x69, 0x64, 0x31, 0x32, 0x38, 0x01]) // "id128" || 0x01
        let saltIK = helper.calculateSalt("nkik".data(using: .ascii)!)!
        identityKey = helper.calculateK1(withN: key, salt: saltIK, andP: P)
        let saltBK = helper.calculateSalt("nkbk".data(using: .ascii)!)!
        beaconKey = helper.calculateK1(withN: key, salt: saltBK, andP: P)
        // Calculate NIC, Encryption Key and Privacy Key.
        let hash = helper.calculateK2(withN: key, andP: Data([0x00]))!
        nid = hash[0] & 0x7F
        encryptionKey = hash.subdata(in: 1..<17)
        privacyKey = hash.subdata(in: 17..<33)
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

// MARK: - Operators

extension NetworkKey: Equatable {
    
    public static func == (lhs: NetworkKey, rhs: NetworkKey) -> Bool {
        return lhs.index == rhs.index
    }
    
    public static func != (lhs: NetworkKey, rhs: NetworkKey) -> Bool {
        return lhs.index != rhs.index
    }
    
}
