//
//  SceneRange.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

public struct SceneRange: Codable, Hashable {
    public let firstScene: Scene
    public let lastScene:  Scene
    
    public init(from firstScene: Scene, to lastScene: Scene) {
        self.firstScene = min(firstScene, lastScene)
        self.lastScene  = max(firstScene, lastScene)
    }
    
    public init(_ range: ClosedRange<Scene>) {
        self.init(from: range.lowerBound, to: range.upperBound)
    }
    
    // MARK: - Codable
    
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

// MARK: - Operators

extension SceneRange: Equatable {
    
    public static func ==(left: SceneRange, right: SceneRange) -> Bool {
        return left.firstScene == right.firstScene && left.lastScene == right.lastScene
    }
    
    public static func ==(left: SceneRange, right: ClosedRange<Scene>) -> Bool {
        return left.firstScene == right.lowerBound && left.lastScene == right.upperBound
    }
    
    public static func !=(left: SceneRange, right: SceneRange) -> Bool {
        return left.firstScene != right.firstScene || left.lastScene != right.lastScene
    }
    
    public static func !=(left: SceneRange, right: ClosedRange<Scene>) -> Bool {
        return left.firstScene != right.lowerBound || left.lastScene != right.upperBound
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
    
    /// Returns whether the given address is in the address range.
    ///
    /// - parameter scene: The scene to be checked.
    /// - returns: `True` if the scene is inside the range.
    func contains(_ scene: Scene) -> Bool {
        return scene >= firstScene && scene <= lastScene
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
    
    /// Returns a sorted array of ranges. If any ranges were overlapping, they
    /// will be merged.
    func merged() -> [SceneRange] {
        var result: [SceneRange] = []
        
        var accumulator = SceneRange(0...0)
        
        for range in sorted(by: { $0.firstScene < $1.firstScene }) {
            if accumulator == 0...0 {
                accumulator = range
            }
            
            if accumulator.lastScene >= range.lastScene {
                // Range is already in accumulator's range.
            }
            
            else if accumulator.lastScene >= range.firstScene {
                accumulator = SceneRange(accumulator.firstScene...range.lastScene)
            }
            
            else /* if accumulator.lastScene < range.firstScene */ {
                result.append(accumulator)
                accumulator = range
            }
        }
        
        if accumulator != 0...0 {
            result.append(accumulator)
        }
        
        return result
    }
    
    /// Merges all overlapping ranges from the array and sorts them.
    mutating func merge() {
        self = merged()
    }
    
    /// Returns whether the given scene is in the scene range array.
    ///
    /// - parameter address: The scene to be checked.
    /// - returns: `True` if the scene is inside the range array.
    func contains(_ scene: Scene) -> Bool {
        return contains { $0.contains(scene) }
    }
    
}

// MARK: - Defaults

public extension SceneRange {
    
    static let allScenes: SceneRange = SceneRange(Scene.minScene...Scene.maxScene)
    
}
