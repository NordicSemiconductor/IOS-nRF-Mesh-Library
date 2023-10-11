/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

/// An alias for the Element type.
public typealias MeshElement = Element

/// An Element is an addressable entity within a ``Node``.
///
/// Each Node has at least one element, the Primary Element, and may have
/// one or more additional secondary elements. The number and structure of
/// elements is static and does not change throughout the lifetime of a node
/// (that is, as long as the node is part of a network).
///
/// The Primary Element is addressed using the first Unicast Address
/// assigned to the Node during provisioning. Each additional secondary
/// element is addressed using the subsequent addresses. These unicast
/// element addresses allow nodes to identify which element within a node
/// is transmitting or receiving a message.
public class Element: Codable {
    /// UTF-8 human-readable name of the Element.
    public var name: String?
    /// Numeric order of the Element within this Node.
    public internal(set) var index: UInt8
    /// Description of the Element's location.
    public internal(set) var location: Location
    /// An array of Model objects in the Element.
    public private(set) var models: [Model]
    
    /// Parent Node. This may be `nil` if the Element was obtained in
    /// Composition Data and has not yet been added to a Node.
    public internal(set) weak var parentNode: Node?
    
    /// This initiator should be used to create Elements that will
    /// be set as local elements using ``MeshNetworkManager/localElements``.
    ///
    /// - parameter name:     The optional Element name.
    /// - parameter location: The Element location, by default set to `.unknown`.
    /// - parameter models:   Array of models belonging to this Element.
    ///                       It must contain at least one Model.
    public init(name: String? = nil, location: Location = .unknown, models: [Model]) {
        guard !models.isEmpty else {
            fatalError("An element must contain at least one model.")
        }
        self.name     = name
        self.location = location
        self.models   = models
        // Set temporary index.
        // Final index will be set when Element is added to the Node.
        self.index = 0
        
        models.forEach {
            $0.parentElement = self
        }
    }
    
    internal init(location: Location) {
        self.location = location
        self.models   = []
        
        // Set temporary index.
        // Final index will be set when Element is added to the Node.
        self.index = 0
    }
    
    internal init?(compositionData: Data, offset: inout Int) {
        // Composition Data must have at least 4 bytes: 2 for Location and one for NumS and NumV.
        guard compositionData.count >= offset + 4 else {
            return nil
        }
        // Is Location valid?
        let rawValue: UInt16 = compositionData.read(fromOffset: offset)
        guard let location = Location(rawValue: rawValue) else {
            return nil
        }
        self.location = location
        
        // Read NumS and NumV.
        let sigModelsByteCount    = Int(compositionData[offset + 2]) * 2 // SIG Model ID is 16-bit long.
        let vendorModelsByteCount = Int(compositionData[offset + 3]) * 4 // Vendor Model ID is 32-bit long.
        
        // Ensure the Composition Data have enough data.
        guard compositionData.count >= offset + 3 + sigModelsByteCount + vendorModelsByteCount else {
            return nil
        }
        // 4 bytes have been read.
        offset += 4
        
        // Set temporary index.
        // Final index will be set when Element is added to the Node.
        self.index = 0
        
        // Read models.
        self.models = []
        for o in stride(from: offset, to: offset + sigModelsByteCount, by: 2) {
            let sigModelId: UInt16 = compositionData.read(fromOffset: o)
            add(model: Model(sigModelId: sigModelId))
        }
        offset += sigModelsByteCount
        
        for o in stride(from: offset, to: offset + vendorModelsByteCount, by: 4) {
            let companyId: UInt16 = compositionData.read(fromOffset: o)
            let vendorModelId: UInt16 = compositionData.read(fromOffset: o + 2)
            add(model: Model(vendorModelId: vendorModelId, companyId: companyId))
        }
        offset += vendorModelsByteCount
    }
    
    internal init(copy element: Element,
                  andTruncateTo applicationKeys: [ApplicationKey], nodes: [Node], groups: [Group]) {
        self.name = element.name
        self.index = element.index
        self.location = element.location
        self.models = element.models.map {
            Model(copy: $0, andTruncateTo: applicationKeys, nodes: nodes, groups: groups)
        }
        self.models.forEach {
            $0.parentElement = self
        }
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
        name  = try container.decodeIfPresent(String.self, forKey: .name)
        index = try container.decode(UInt8.self, forKey: .index)
        let locationAsString = try container.decode(String.self, forKey: .location)
        guard let rawValue = UInt16(hex: locationAsString) else {
            throw DecodingError.dataCorruptedError(forKey: .location, in: container,
                                                   debugDescription: "Location must be 4-character hexadecimal string.")
        }
        guard let loc = Location(rawValue: rawValue) else {
            throw DecodingError.dataCorruptedError(forKey: .location, in: container,
                                                   debugDescription: "Unknown location: 0x\(locationAsString).")
        }
        location = loc
        models = try container.decode([Model].self, forKey: .models)
        
        models.forEach {
            $0.parentElement = self
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(index, forKey: .index)
        try container.encode(location.hex, forKey: .location)
        try container.encode(models, forKey: .models)
    }
}

// MARK: - Operators

extension Element: Equatable, Hashable {
    
    public static func == (lhs: Element, rhs: Element) -> Bool {
        return lhs.parentNode === rhs.parentNode 
            && lhs.index == rhs.index
            && lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(unicastAddress)
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
    
    /// Inserts the given model to the Element at the specified position.
    ///
    /// - parameter model: The model to be added.
    func insert(model: Model, at i: Int) {
        models.insert(model, at: i)
        model.parentElement = self
    }
    
    /// This methods adds the natively supported Models to the Element.
    ///
    /// This method should only be called for the primary Element of the
    /// local Node.
    ///
    /// - parameter meshNetwork: The mesh network object.
    func addPrimaryElementModels(_ meshNetwork: MeshNetwork) {
        guard isPrimary else { return }
        insert(model: Model(sigModelId: .configurationServerModelId,
                            delegate: ConfigurationServerHandler(meshNetwork)), at: 0)
        insert(model: Model(sigModelId: .configurationClientModelId,
                            delegate: ConfigurationClientHandler(meshNetwork)), at: 1)
        insert(model: Model(sigModelId: .healthServerModelId), at: 2)
        insert(model: Model(sigModelId: .healthClientModelId), at: 3)
        insert(model: Model(sigModelId: .privateBeaconClientModelId,
                            delegate: PrivateBeaconClientHandler(meshNetwork)), at: 4)
        insert(model: Model(sigModelId: .sarConfigurationClientModelId,
                            delegate: SarConfigurationClientHandler(meshNetwork)), at: 5)
        insert(model: Model(sigModelId: .remoteProvisioningClientModelId,
                            delegate: RemoteProvisioningClientHandler(meshNetwork)), at: 6)
        insert(model: Model(sigModelId: .sceneClientModelId,
                            delegate: SceneClientHandler(meshNetwork)), at: 7)
    }
    
    /// Removes the models that are or should be supported natively.
    func removePrimaryElementModels() {
        models = models.filter { model in
            // Health models are not yet supported.
            !model.isHealthServer &&
            !model.isHealthClient &&
            // The library supports Scene Client model natively.
            !model.isSceneClient &&
            // The models that require Device Key should not be managed by users.
            // Some of them are supported natively in the library.
            !model.requiresDeviceKey
        }
    }
    
    /// The primary Element for Provisioner's Node.
    ///
    /// The Element will contain all mandatory Models (Configuration Server
    /// and Health Server) and supported clients (Configuration Client
    /// and Health Client).
    static var primaryElement: Element {
        // The Provisioner will always have a first Element with obligatory
        // Models.
        let element = Element(location: .unknown)
        element.name = "Primary Element"
        // Configuration Server is required for all nodes.
        element.add(model: Model(sigModelId: .configurationServerModelId))
        // Configuration Client is added, as this is a Provisioner's node.
        element.add(model: Model(sigModelId: .configurationClientModelId))
        // Health Server is required for all nodes.
        element.add(model: Model(sigModelId: .healthServerModelId))
        // Health Client is added, as this is a Provisioner's node.
        element.add(model: Model(sigModelId: .healthClientModelId))
        return element
    }
    
}

extension Element: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "\(name ?? "Element \(index)") (0x\(unicastAddress.hex))"
    }
    
}
