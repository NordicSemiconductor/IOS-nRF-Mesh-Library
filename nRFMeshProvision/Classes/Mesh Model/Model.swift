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
    /// The Company Identifier or nil, if the model is Bluetooth SIG-assigned.
    public var companyIdentifier: UInt16? {
        if modelId > 0xFFFF {
            return UInt16(modelId >> 16)
        }
        return nil
    }
    /// Rerturns `true` for model with identifiers assigned by Bluetooth SIG,
    /// `false` otherwise.
    public var isBluetoothSIGAssigned: Bool {
        return modelId <= 0xFFFF
    }
    /// The array of unicast or group addresses (4-character hexadecimal value),
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
    /// An array of appliaction key indexes to which this model is bound.
    public internal(set) var bind: [KeyIndex]
}
