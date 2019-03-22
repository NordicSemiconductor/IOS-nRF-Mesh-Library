//
//  MeshUUID.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

/// The wrapper for Unified Unique Identifier (UUID).
/// The reason for the wrapper is to ensure that it is encoded without dashes.
public class MeshUUID: Codable {
    /// The underlying UUID.
    private let uuid: UUID
    
    /// Returns UUID as String, with dashes.
    public var uuidString: String {
        return uuid.uuidString
    }
    
    /// Generates new random Mesh UUID.
    public init() {
        self.uuid = UUID()
    }
    
    /// Initializes Mesh UUID with given UUID.
    public init(_ uuid: UUID) {
        self.uuid = uuid
    }
    
    // MARK: - Codable
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        if let result = UUID(uuidString: value) {
            uuid = result
            return
        }
        
        if let result = UUID(uuidString: MeshUUID.addDashes(value)) {
            uuid = result
            return
        }
        
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid UUID: \(value)")
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(MeshUUID.removeDashes(uuidString))
    }
    
    // MARK: - Helper methods
    
    /// Removes dashes to match 32-character UUID representation.
    private static func removeDashes(_ uuidString: String) -> String {
        return uuidString.replacingOccurrences(of: "-", with: "")
    }
    
    /// Adds dashes to 32-character UUID string representation.
    private static func addDashes(_ uuidString: String) -> String {
        var result = ""
        
        for (offset, character) in uuidString.enumerated() {
            if offset == 8 || offset == 12 || offset == 16 || offset == 20 {
                result.append("-")
            }
            result.append(character)
        }
        return result
    }
}
