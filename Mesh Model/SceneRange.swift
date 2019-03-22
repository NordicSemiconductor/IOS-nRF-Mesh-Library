//
//  SceneRange.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

public typealias SceneRange = ClosedRange<Scene>

// MARK: - Codable

extension ClosedRange: Codable where Bound == Scene {
    
    private enum CodingKeys: String, CodingKey {
        case lowerBound = "firstScene"
        case upperBound = "lastScene"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lowerBound = try container.decode(Scene.self, forKey: .lowerBound)
        let upperBound = try container.decode(Scene.self, forKey: .upperBound)
        self = lowerBound...upperBound
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lowerBound, forKey: .lowerBound)
        try container.encode(upperBound, forKey: .upperBound)
    }
}

// MARK: - Helper methods

public extension ClosedRange where Bound == Scene {
    
    /// Returns true if the scene range is valid.
    ///
    /// - returns: True if the scene range is valid.
    public func isValid() -> Bool {
        return lowerBound.isValidScene() && upperBound.isValidScene()
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
                
            }
        }
    }
}

// MARK: - Overlapping

public extension ClosedRange where Bound == Scene {
    
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
        return (lowerBound < other.lowerBound && upperBound < other.lowerBound)
            || (other.lowerBound < lowerBound && other.upperBound < lowerBound)
    }
    
}

// MARK: - Defaults

public extension ClosedRange where Bound == Scene {
    
    public static let allScenes: SceneRange = Scene.minScene...Scene.maxScene
    
}
