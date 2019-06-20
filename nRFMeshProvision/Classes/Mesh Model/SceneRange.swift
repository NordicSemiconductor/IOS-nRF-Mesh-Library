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
