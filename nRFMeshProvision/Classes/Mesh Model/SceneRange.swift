//
//  SceneRange.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

public class SceneRange: RangeObject, Codable {
    
    public var firstScene: Address {
        return range.lowerBound
    }
    
    public var lastScene: Address {
        return range.upperBound
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case firstScene
        case lastScene
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let firstSceneAsString = try container.decode(String.self, forKey: .firstScene)
        let lastSceneAsString  = try container.decode(String.self, forKey: .lastScene)
        
        guard let firstScene = Scene(hex: firstSceneAsString) else {
            throw DecodingError.dataCorruptedError(forKey: .firstScene, in: container,
                                                   debugDescription: "Scene must be 4-character hexadecimal string")
        }
        guard let lastScene = Scene(hex: lastSceneAsString) else {
            throw DecodingError.dataCorruptedError(forKey: .lastScene, in: container,
                                                   debugDescription: "Scene must be 4-character hexadecimal string")
        }
        self.init(from: firstScene, to: lastScene)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(range.lowerBound.hex, forKey: .firstScene)
        try container.encode(range.upperBound.hex, forKey: .lastScene)
    }
}

// MARK: - Public API

public extension SceneRange {
    
    /// Returns true if the scene range is valid.
    ///
    /// - returns: True if the scene range is valid.
    var isValid: Bool {
        return firstScene.isValidScene && lastScene.isValidScene
    }
    
    /// Returns true if this and the given Scene Range overlapps.
    ///
    /// - parameter range: The range to check overlapping.
    /// - returns: True if ranges overlap.
    func overlaps(_ other: SceneRange) -> Bool {
        return !doesNotOverlap(other)
    }
    
    /// Returns true if this and the given Scene Range do not overlap.
    ///
    /// - parameter range: The range to check overlapping.
    /// - returns: True if ranges do not overlap.
    func doesNotOverlap(_ other: SceneRange) -> Bool {
        return (firstScene < other.firstScene && lastScene < other.firstScene)
            || (other.firstScene < firstScene && other.lastScene < firstScene)
    }
    
}

public extension Array where Element == SceneRange {
    
    /// Returns true if all the scene ranges are valid.
    ///
    /// - returns: True if the all scene ranges are valid.
    var isValid: Bool {
        for range in self {
            if !range.isValid {
                return false
            }
        }
        return true
    }
    
}

// MARK: - Defaults

public extension SceneRange {
    
    static let allScenes: SceneRange = SceneRange(Scene.minScene...Scene.maxScene)
    
}
