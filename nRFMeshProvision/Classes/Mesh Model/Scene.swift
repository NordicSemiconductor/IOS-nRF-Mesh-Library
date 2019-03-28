//
//  Scene.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

/// Scene number type. Type alias for UInt16.
public typealias Scene = UInt16

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
