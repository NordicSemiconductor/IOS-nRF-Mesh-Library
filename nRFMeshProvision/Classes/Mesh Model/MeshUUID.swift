//
//  MeshUUID.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

/// The wrapper for Unified Unique Identifier (UUID).
/// The reason for the wrapper is to ensure that it is encoded without dashes.
internal class MeshUUID: Codable {
    /// The underlying UUID.
    let uuid: UUID
    
    /// Returns UUID as String, with dashes.
    var uuidString: String {
        return uuid.uuidString
    }
    
    /// Generates new random Mesh UUID.
    init() {
        self.uuid = UUID()
    }
    
    /// Initializes Mesh UUID with given UUID.
    init(_ uuid: UUID) {
        self.uuid = uuid
    }
    
    // MARK: - Codable
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        if let result = UUID(uuidString: value) {
            uuid = result
            return
        }
        
        if let result = UUID(hex: value) {
            uuid = result
            return
        }
        
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid UUID: \(value)")
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(uuid.hex)
    }
}

// MARK: - Operators

extension MeshUUID: Equatable {
    
    public static func == (lhs: MeshUUID, rhs: MeshUUID) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    public static func == (lhs: MeshUUID, rhs: UUID) -> Bool {
        return lhs.uuid == rhs
    }
    
    public static func != (lhs: MeshUUID, rhs: MeshUUID) -> Bool {
        return lhs.uuid != rhs.uuid
    }
    
    public static func != (lhs: MeshUUID, rhs: UUID) -> Bool {
        return lhs.uuid != rhs
    }
    
}
