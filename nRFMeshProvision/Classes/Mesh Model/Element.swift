//
//  Element.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 26/03/2019.
//

import Foundation

public class Element: Codable {
    /// UTF-8 human-readable name of the element.
    public var name: String?
    /// Numeric order of the element within this node.
    public internal(set) var index: UInt8
    /// Description of the element's location.
    public internal(set) var location: Location
    /// An array of model objects in the element.
    public internal(set) var models: [Model]
    
    internal init(index: UInt8, location: Location) {
        self.index = index
        self.location = location
        self.models = []
    }
}
