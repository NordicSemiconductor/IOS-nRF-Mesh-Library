//
//  Scene.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

public typealias Scene = UInt16

/*public class Scene: Codable {
    
    public let scene: UInt16
    
    public init(_ scene: UInt16) {
        self.scene = scene
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        
        guard let scene = UInt16(hex: string) else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Scene must be 4-character hexadecimal string")
        }
        self.scene = scene
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(scene.hex)
    }
}*/

extension Scene {
    
    public static let invalid:  Scene = 0x0000
    public static let minScene: Scene = 0x0001
    public static let maxScene: Scene = 0xFFFF
    
}

// MARK: - Helper methods

extension Scene {
    
    /// Returns true if the scene number is valid.
    /// Valid scenes have numbers from minScene to maxScene.
    public var isValidScene: Bool {
        return self != Scene.invalid
    }
    
}
