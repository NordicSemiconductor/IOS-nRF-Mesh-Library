//
//  ApplicationKey.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

public class ApplicationKey: Key, Codable {
    /// UTF-8 string, which should be a human readable name for the application
    /// functionality associated with this application key, e.g. "Home Automation".
    public var name: String
    /// Index of this Application Key, in range from 0 through to 4095.
    public internal(set) var index: KeyIndex
    /// Corresponding Network Key index from the Network Keys array.
    public internal(set) var boundNetKey: KeyIndex
    /// 128-bit application key.
    public internal(set) var key: Data {
        willSet {
            oldKey = key
            oldAid = aid
        }
        didSet {
            regenerateKeyDerivaties()
        }
    }
    /// Previous 128-bit application key, if Key Update procedure is in progress.
    public internal(set) var oldKey: Data? {
        didSet {
            if oldKey == nil {
                oldAid = nil
            }
        }
    }
    
    /// Application Key identifier.
    internal var aid: UInt8!
    /// Application Key identifier derived from the old key.
    internal var oldAid: UInt8?
    
    internal init(name: String, index: KeyIndex, key: Data, bindTo networkKey: NetworkKey) throws {
        guard index.isValidKeyIndex else {
            throw MeshModelError.keyIndexOutOfRange
        }
        self.name        = name
        self.index       = index
        self.key         = key
        self.boundNetKey = networkKey.index
        
        regenerateKeyDerivaties()
    }
    
    // MARK: - Codable
    
    /// Coding keys used to export / import Application Keys.
    enum CodingKeys: String, CodingKey {
        case name
        case index
        case key
        case oldKey
        case boundNetKey
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
        if let oldKeyHex = try container.decodeIfPresent(String.self, forKey: .oldKey) {
            guard let oldKeyData = Data(hex: oldKeyHex) else {
                throw DecodingError.dataCorruptedError(forKey: .oldKey, in: container,
                                                       debugDescription: "Old key must be 32-character hexadecimal string")
            }
            oldKey = oldKeyData
        }
        boundNetKey = try container.decode(KeyIndex.self, forKey: .boundNetKey)
        
        regenerateKeyDerivaties()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(index, forKey: .index)
        try container.encode(key.hex, forKey: .key)
        try container.encodeIfPresent(oldKey?.hex, forKey: .oldKey)
        try container.encode(boundNetKey, forKey: .boundNetKey)
    }
    
    private func regenerateKeyDerivaties() {
        let helper = OpenSSLHelper()
        aid = helper.calculateK4(withN: key)
        
        // When the Application Key is imported from JSON, old key derivaties must
        // be calculated.
        if let oldKey = oldKey, oldAid == nil {
            oldAid = helper.calculateK4(withN: oldKey)
        }
    }
    
}

// MARK: - Operators

extension ApplicationKey: Equatable {
    
    public static func == (lhs: ApplicationKey, rhs: ApplicationKey) -> Bool {
        return lhs.index == rhs.index && lhs.key == rhs.key
    }
    
    public static func != (lhs: ApplicationKey, rhs: ApplicationKey) -> Bool {
        return lhs.index != rhs.index || lhs.key != rhs.key
    }
    
}
