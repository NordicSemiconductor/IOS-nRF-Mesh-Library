//
//  SceneRange.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

public struct SceneRange: Codable {
    public let firstScene: Scene
    public let lastScene:  Scene
    
    public init(from firstScene: Scene, to lastScene: Scene) {
        self.firstScene = min(firstScene, lastScene)
        self.lastScene  = max(firstScene, lastScene)
    }
    
    public init(_ range: ClosedRange<Scene>) {
        self.init(from: range.lowerBound, to: range.upperBound)
    }
    
    private enum CodingKeys: String, CodingKey {
        case firstScene
        case lastScene
    }
    
    public init(from decoder: Decoder) throws {
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
        try container.encode(firstScene.hex, forKey: .firstScene)
        try container.encode(lastScene.hex,  forKey: .lastScene)
    }
}

// MARK: - Helper methods

public extension SceneRange {
    
    /// Returns true if the scene range is valid.
    ///
    /// - returns: True if the scene range is valid.
    public func isValid() -> Bool {
        return firstScene.isValidScene() && lastScene.isValidScene()
    }
    
}

public extension Array where Element == SceneRange {
    
    /// Returns true if all the scene ranges are valid.
    ///
    /// - returns: True if the all scene ranges are valid.
    public func isValid() -> Bool {
        for range in self {
            if !range.isValid() {
                return false
            }
        }
        return true
    }
    
    public mutating func append(_ newElement: Element) {
        for range in self {
            if range.overlaps(with: newElement) {
                // TODO
            }
        }
    }
}

// MARK: - Overlapping

public extension SceneRange {
    
    /// Returns true if this and the given Scene Range overlapps.
    ///
    /// - parameter range: The range to check overlapping.
    /// - returns: True if ranges overlap.
    public func overlaps(with other: SceneRange) -> Bool {
        return !doesNotOverlap(with: other)
    }
    
    /// Returns true if this and the given Scene Range do not overlap.
    ///
    /// - parameter range: The range to check overlapping.
    /// - returns: True if ranges do not overlap.
    public func doesNotOverlap(with other: SceneRange) -> Bool {
        return (firstScene < other.firstScene && lastScene < other.firstScene)
            || (other.firstScene < firstScene && other.lastScene < firstScene)
    }
    
}

// MARK: - Defaults

public extension SceneRange {
    
    public static let allScenes: SceneRange = SceneRange(Scene.minScene...Scene.maxScene)
    
}
