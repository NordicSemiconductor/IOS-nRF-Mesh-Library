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
    /// or virtual label UUIDs (32-character hexadecimal string).
    internal var subscribe: [String]
    /// Returns the list of Groups that this model is subscribed to.
    public var subscriptions: [Group] {
        return parentElement.parentNode?.meshNetwork?.groups.filter({ subscribe.contains($0._address )}) ?? []
    }
    /// The configuration of this model's publication.
    public internal(set) var publish: Publish?
    /// An array of Appliaction Key indexes to which this model is bound.
    internal var bind: [KeyIndex]
    
    /// Parent Element.
    public internal(set) weak var parentElement: Element!
    
    internal init(sigModelId: UInt16) {
        self.modelId   = UInt32(sigModelId)
        self.subscribe = []
        self.bind      = []
    }
    
    internal init(vendorModelId: UInt32) {
        self.modelId   = vendorModelId
        self.subscribe = []
        self.bind      = []
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

internal extension Model {
    
    static let configurationServer = Model(sigModelId: 0x0000)
    static let configurationClient = Model(sigModelId: 0x0001)
    static let healthServer = Model(sigModelId: 0x0002)
    static let healthClient = Model(sigModelId: 0x0003)
    
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
    /// - parameter: The new Group to be added.
    func subscribe(to group: Group) {
        let address = group.address.hex
        if !subscribe.contains(address) {
            subscribe.append(address)
        }
    }
    
    /// Removes the given Group from list of subscriptions.
    ///
    /// - parameter: The Group to be removed.
    func unsubscribe(from group: Group) {
        let address = group.address.hex
        if let index = subscribe.firstIndex(of: address) {
            subscribe.remove(at: index)
        }
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
