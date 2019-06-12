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
    /// Returns `true` for model with identifiers assigned by Bluetooth SIG,
    /// `false` otherwise.
    public var isBluetoothSIGAssigned: Bool {
        return modelId <= 0xFFFF
    }
    /// The array of Unicast or Group Addresses (4-character hexadecimal value),
    /// or virtual label UUIDs (32-character hexadecimal string).
    internal var subscribe: [String]
    /// Returns the list of addresses subscribed to this model.
    public var subscribers: [MeshAddress] {
        return subscribe.map {
            // Warning: assuming hex addresses are valid!
            return MeshAddress(hex: $0)!
        }
    }
    /// The configuration of this model's publication.
    public internal(set) var publish: Publish?
    /// An array of Appliaction Key indexes to which this model is bound.
    public internal(set) var bind: [KeyIndex]
    
    /// Parent Element.
    public internal(set) weak var parentElement: Element!
    
    internal init(modelId: UInt32) {
        self.modelId   = modelId
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
        guard let modelId = UInt32(hex: modelIdString) else {
            throw DecodingError.dataCorruptedError(forKey: .modelId, in: container,
                                                   debugDescription: "Model ID must be 4-character hexadecimal string")
        }
        self.modelId = modelId
        self.subscribe = try container.decode([String].self, forKey: .subscribe)
        if let publish = try container.decodeIfPresent(Publish.self, forKey: .publish) {
            self.publish = publish
        }
        self.bind = try container.decode([KeyIndex].self, forKey: .bind)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(modelId.hex, forKey: .modelId)
        try container.encode(subscribe, forKey: .subscribe)
        try container.encodeIfPresent(publish, forKey: .publish)
        try container.encode(bind, forKey: .bind)
    }
}

extension Model {
    
    static let configurationServer = Model(modelId: 0x0000)
    static let configurationClient = Model(modelId: 0x0001)
    static let healthServer = Model(modelId: 0x0002)
    static let healthClient = Model(modelId: 0x0003)
    
}
