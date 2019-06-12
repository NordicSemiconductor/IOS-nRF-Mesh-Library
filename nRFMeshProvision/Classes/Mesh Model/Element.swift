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
    
    /// Parent Node.
    public internal(set) weak var parentNode: Node!
    
    internal init(location: Location) {
        self.location = location
        self.models = []
        
        // Set temporary index.
        // Final index will be set when Element is added to the Node.
        self.index = 0
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: CodingKey {
        case name
        case index
        case location
        case models
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name  = try container.decode(String.self, forKey: .name)
        index  = try container.decode(UInt8.self, forKey: .index)
        location  = try container.decode(Location.self, forKey: .location)
        models  = try container.decode([Model].self, forKey: .models)
        
        models.forEach {
            $0.parentElement = self
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(index, forKey: .index)
        try container.encode(location, forKey: .location)
        try container.encode(models, forKey: .models)
    }
}

// MARK: - Operators

extension Element: Equatable {
    
    public static func == (lhs: Element, rhs: Element) -> Bool {
        return lhs.parentNode === rhs.parentNode && lhs.index == rhs.index
    }
    
    public static func != (lhs: Element, rhs: Element) -> Bool {
        return lhs.parentNode !== rhs.parentNode || lhs.index != rhs.index
    }
    
}


internal extension Element {
    
    /// Adds given model to the Element.
    ///
    /// - parameter model: The model to be added.
    func add(model: Model) {
        models.append(model)
        model.parentElement = self
    }
    
}
