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

// MARK: - Operators

public extension SceneRange {
    
    static func +(left: SceneRange, right: SceneRange) -> [SceneRange] {
        if left.overlaps(right) {
            return [SceneRange(min(left.lowerBound, right.lowerBound)...max(left.upperBound, right.upperBound))]
        }
        return [left, right]
    }
    
    static func -(left: SceneRange, right: SceneRange) -> [SceneRange] {
        var result: [SceneRange] = []
        
        // Left:   |------------|                    |-----------|                 |---------|
        //                  -                              -                            -
        // Right:      |-----------------|   or                     |---|   or        |----|
        //                  =                              =                            =
        // Result: |---|                             |-----------|                 |--|
        if right.lowerBound > left.lowerBound {
            let leftSlice = SceneRange(left.lowerBound...(min(left.upperBound, right.lowerBound - 1)))
            result.append(leftSlice)
        }
        
        // Left:                |----------|             |-----------|                     |--------|
        //                         -                          -                             -
        // Right:      |----------------|           or       |----|          or     |---|
        //                         =                          =                             =
        // Result:                      |--|                      |--|                     |--------|
        if right.upperBound < left.upperBound {
            let rightSlice = SceneRange(max(right.upperBound + 1, left.lowerBound)...left.upperBound)
            result.append(rightSlice)
        }
        
        return result
    }
    
}

public extension Array where Element == SceneRange {
    
    static func +=(array: inout [SceneRange], other: SceneRange) {
        array.append(other)
        array.merge()
    }
    
    static func +=(array: inout [SceneRange], otherArray: [SceneRange]) {
        array.append(contentsOf: otherArray)
        array.merge()
    }
    
    static func -=(array: inout [SceneRange], other: SceneRange) {
        var result: [SceneRange] = []
        
        for scene in array {
            result += scene - other
        }
        array.removeAll()
        array.append(contentsOf: result)
    }
    
}

// MARK: - Public API

public extension SceneRange {
    
    /// Returns `true` if the scene range is valid.
    ///
    /// - returns: `True` if the scene range is valid, `false` otherwise.
    var isValid: Bool {
        return firstScene.isValidScene && lastScene.isValidScene
    }
    
}

public extension Array where Element == SceneRange {
    
    /// Returns `true` if all the scene ranges are valid.
    ///
    /// - returns: `True` if the all scene ranges are valid, `false` otherwise.
    var isValid: Bool {
        return !contains{ !$0.isValid }
    }
    
}

// MARK: - Defaults

public extension SceneRange {
    
    static let allScenes: SceneRange = SceneRange(Scene.minScene...Scene.maxScene)
    
}
