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

/// Application Keys are used to encrypt mesh messages on Access Layer.
///
/// The Application Key is 128-bit long and is bound to a single Network Key.
/// To use the Application Key, the bound Network Key must be used to encrypt
/// the message on Network Layer.
///
/// Each key is identified by a ``KeyIndex``. There can be up to 4095
/// Application Keys in a mesh network.
///
/// AID (Application Key identifier) is derived from the Application Key.
///
/// The key can be change using Key Refresh Procedure (KRP).
public class ApplicationKey: Key, Codable {
    internal weak var meshNetwork: MeshNetwork?
    
    /// UTF-8 string, which should be a human readable name for the application
    /// functionality associated with this application key, e.g. "Home Automation".
    public var name: String
    /// Index of this Application Key, in range from 0 through to 4095.
    public internal(set) var index: KeyIndex
    /// Corresponding Network Key index from the Network Keys array.
    public internal(set) var boundNetworkKeyIndex: KeyIndex {
        didSet {
            meshNetwork?.timestamp = Date()
        }
    }
    /// 128-bit application key.
    public internal(set) var key: Data {
        willSet {
            oldKey = key
            oldAid = aid
        }
        didSet {
            regenerateKeyDerivatives()
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
    
    internal init(name: String, index: KeyIndex, key: Data, boundTo networkKey: NetworkKey) throws {
        guard key.count == 16 else {
            throw MeshNetworkError.invalidKey
        }
        guard index.isValidKeyIndex else {
            throw MeshNetworkError.keyIndexOutOfRange
        }
        self.name = name
        self.index = index
        self.key = key
        self.boundNetworkKeyIndex = networkKey.index
        
        regenerateKeyDerivatives()
    }
    
    private func regenerateKeyDerivatives() {
        aid = Crypto.calculateAid(from: key)
        
        // When the Application Key is imported from JSON, old key derivatives must
        // be calculated.
        if let oldKey = oldKey, oldAid == nil {
            oldAid = Crypto.calculateAid(from: oldKey)
        }
    }
    
    // MARK: - Codable
    
    /// Coding keys used to export / import Application Keys.
    enum CodingKeys: String, CodingKey {
        case name
        case index
        case key
        case oldKey
        case boundNetworkKeyIndex = "boundNetKey"
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        index = try container.decode(KeyIndex.self, forKey: .index)
        let keyHex = try container.decode(String.self, forKey: .key)
        key = Data(hex: keyHex)
        guard !key.isEmpty else {
            throw DecodingError.dataCorruptedError(forKey: .key, in: container,
                                                   debugDescription: "Key must be 32-character hexadecimal string.")
        }
        if let oldKeyHex = try container.decodeIfPresent(String.self, forKey: .oldKey) {
            oldKey = Data(hex: oldKeyHex)
            guard !oldKey!.isEmpty else {
                throw DecodingError.dataCorruptedError(forKey: .oldKey, in: container,
                                                       debugDescription: "Old key must be 32-character hexadecimal string.")
            }
        }
        boundNetworkKeyIndex = try container.decode(KeyIndex.self, forKey: .boundNetworkKeyIndex)
        
        regenerateKeyDerivatives()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(index, forKey: .index)
        try container.encode(key.hex, forKey: .key)
        try container.encodeIfPresent(oldKey?.hex, forKey: .oldKey)
        try container.encode(boundNetworkKeyIndex, forKey: .boundNetworkKeyIndex)
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

extension ApplicationKey: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "\(name) (index: \(index))"
    }
    
}
