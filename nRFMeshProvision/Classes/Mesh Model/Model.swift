//
//  Model.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 26/03/2019.
//

import Foundation

public class Model: Codable {
    /// Bluetooth SIG-defined model identifier, of a vendor-defined model
    /// identifier. In the latter case, the first 4 bytes correspond to
    /// a Bluetooth-assigned Company Identifier, and the 4 least significant
    /// bytes a vendor-assigned model identifier.
    internal let modelId: UInt32
    /// Bluetooth SIG or vendor-assigned model identifier.
    public var modelIdentifier: UInt16 {
        return UInt16(modelId & 0x0000FFFF)
    }
    /// The Company Identifier or `nil`, if the model is Bluetooth SIG-assigned.
    public var companyIdentifier: UInt16? {
        if modelId > 0xFFFF {
            return UInt16(modelId >> 16)
        }
        return nil
    }
    /// Returns `true` for Models with identifiers assigned by Bluetooth SIG,
    /// `false` otherwise.
    public var isBluetoothSIGAssigned: Bool {
        return modelId <= 0xFFFF
    }
    /// The array of Unicast or Group Addresses (4-character hexadecimal value),
    /// or Virtual Label UUIDs (32-character hexadecimal string).
    internal var subscribe: [String]
    /// Returns the list of known Groups that this Model is subscribed to.
    /// It may be that the Model is subscribed to some other Groups, which are
    /// not known to the local database, and those are not returned.
    /// Use `isSubscribed(to:)` to check other Groups.
    public var subscriptions: [Group] {
        return parentElement.parentNode?.meshNetwork?.groups
            .filter({ subscribe.contains($0._address )}) ?? []
    }
    /// The configuration of this Model's publication.
    public internal(set) var publish: Publish?
    /// An array of Appliaction Key indexes to which this model is bound.
    internal var bind: [KeyIndex]
    
    /// The model message handler. This is non-`nil` for supported local Models
    /// and `nil` for Models of remote Nodes.
    public let handler: ModelHandler?
    
    /// Parent Element.
    public internal(set) weak var parentElement: Element!
    
    internal init(vendorModelId: UInt32) {
        self.modelId   = vendorModelId
        self.subscribe = []
        self.bind      = []
        self.handler   = nil
    }
    
    internal convenience init(sigModelId: UInt16) {
        self.init(vendorModelId: UInt32(sigModelId))
    }
    
    public init(vendorModelId: UInt32, handler: ModelHandler) {
        self.modelId   = vendorModelId
        self.subscribe = []
        self.bind      = []
        self.handler   = handler
    }
    
    public convenience init(modelId: UInt16, companyId: UInt16, handler: ModelHandler) {
        let vendorModelId = (UInt32(companyId) << 16) | UInt32(modelId)
        self.init(vendorModelId: vendorModelId, handler: handler)
    }
    
    public convenience init(sigModelId: UInt16, handler: ModelHandler) {
        self.init(vendorModelId: UInt32(sigModelId), handler: handler)
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: CodingKey {
        case modelId
        case subscribe
        case publish
        case bind
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let modelIdString  = try container.decode(String.self, forKey: .modelId)
        if modelIdString.count == 4 {
            guard let modelId = UInt16(hex: modelIdString) else {
                throw DecodingError.dataCorruptedError(forKey: .modelId, in: container,
                                                       debugDescription: "Model ID must be 4-character hexadecimal string")
            }
            self.modelId = UInt32(modelId)
        } else {
            guard let modelId = UInt32(hex: modelIdString) else {
                throw DecodingError.dataCorruptedError(forKey: .modelId, in: container,
                                                       debugDescription: "Vendor Model ID must be 8-character hexadecimal string")
            }
            self.modelId = modelId
        }
        self.subscribe = try container.decode([String].self, forKey: .subscribe)
        if let publish = try container.decodeIfPresent(Publish.self, forKey: .publish) {
            self.publish = publish
        }
        self.bind = try container.decode([KeyIndex].self, forKey: .bind)
        self.handler = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if isBluetoothSIGAssigned {
            try container.encode(modelIdentifier.hex, forKey: .modelId)
        } else {
            try container.encode(modelId.hex, forKey: .modelId)
        }
        try container.encode(subscribe, forKey: .subscribe)
        try container.encodeIfPresent(publish, forKey: .publish)
        try container.encode(bind, forKey: .bind)
    }
}

internal extension UInt16 {
    
    static let configurationServerModelId: UInt16 = 0x0000
    static let configurationClientModelId: UInt16 = 0x0001
    static let healthServerModelId: UInt16 = 0x0002
    static let healthClientModelId: UInt16 = 0x0003
    
}

internal extension Model {
    
    var isConfigurationServer: Bool { modelId == UInt32(UInt16.configurationServerModelId) }
    var isConfigurationClient: Bool { modelId == UInt32(UInt16.configurationClientModelId) }
    var isHealthServer: Bool { modelId == UInt32(UInt16.healthServerModelId) }
    var isHealthClient: Bool { modelId == UInt32(UInt16.healthClientModelId) }
    
}

internal extension Model {
    
    /// Adds the given Application Key Index to the bound keys.
    ///
    /// - paramter applicationKeyIndex: The Application Key index to bind.
    func bind(applicationKeyWithIndex applicationKeyIndex: KeyIndex) {
        guard !bind.contains(applicationKeyIndex) else {
            return
        }
        bind.append(applicationKeyIndex)
        bind.sort()
    }
    
    /// Removes the Application Key binding to with the given Key Index
    /// and clears the publication, if it was set to use the same key.
    ///
    /// - parameter applicationKeyIndex: The Application Key index to unbind.
    func unbind(applicationKeyWithIndex applicationKeyIndex: KeyIndex) {
        if let index = bind.firstIndex(of: applicationKeyIndex) {
            bind.remove(at: index)
            // If this Application Key was used for publication, the publication has been cancelled.
            if let publish = publish, publish.index == applicationKeyIndex {
                self.publish = nil
            }
        }
    }
    
    /// Adds the given Group to the list of subscriptions.
    ///
    /// - parameter group: The new Group to be added.
    func subscribe(to group: Group) {
        let address = group.address.hex
        if !subscribe.contains(address) {
            subscribe.append(address)
        }
    }
    
    /// Removes the given Group from list of subscriptions.
    ///
    /// - parameter group: The Group to be removed.
    func unsubscribe(from group: Group) {
        let address = group.address.hex
        if let index = subscribe.firstIndex(of: address) {
            subscribe.remove(at: index)
        }
    }
    
    /// Removes the given Address from list of subscriptions.
    ///
    /// - parameter address: The Address to be removed.
    func unsubscribe(from address: Address) {
        let address = address.hex
        if let index = subscribe.firstIndex(of: address) {
            subscribe.remove(at: index)
        }
    }
    
    /// Removes all subscribtions from this Model.
    func unsubscribeFromAll() {
        subscribe.removeAll()
    }
    
}

extension Model: Equatable {
    
    public static func == (lhs: Model, rhs: Model) -> Bool {
        return lhs.modelId == rhs.modelId
    }
    
    public static func != (lhs: Model, rhs: Model) -> Bool {
        return lhs.modelId != rhs.modelId
    }
    
}
