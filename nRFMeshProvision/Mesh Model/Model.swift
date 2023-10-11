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

/// A Model defines the basic functionality of a ``Node``.
///
/// A Node may include one or more ``Element``, each with one or mode models.
/// A model defines the required states, the messages that act upon those states,
/// and any associated behavior.
///
/// Two Models with the same ``Model/modelId`` cannot be located on the same Element.
///
/// A Model may extend another Model. Models in Extend relationship may share states.
/// A Model which does not extend any other Model is called a *base* Model.
///
/// Models in Extend relationship located on the same Element share the Subsctiption List.
public class Model: Codable {
    /// Bluetooth SIG or vendor-assigned model identifier.
    ///
    /// In case of vendor models the 2 most significant bytes of this property are
    /// the Company Identifier, as registersd in Bluetooth SIG Assigned Numbers database.
    ///
    /// For Bluetooth SIG defined models these 2 bytes are `0x0000`.
    ///
    /// Use ``Model/modelIdentifier`` to get the 16-bit model identifier and
    /// ``Model/companyIdentifier`` to obtain the Company Identifier.
    ///
    /// Use ``Model/isBluetoothSIGAssigned`` to check whether the Model is defined by
    /// Bluetooth SIG.
    /// 
    /// - since: 4.0.0
    public let modelId: UInt32
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
    /// The array of Group Addresses (4-character hexadecimal string),
    /// or Virtual Label UUIDs (32-character hexadecimal string).
    internal private(set) var subscribe: [String]
    /// Returns the list of known Groups that this Model is subscribed to.
    /// Models on the Primary Element are also subscribed to the All Nodes address.
    ///
    /// It may be that the Model is subscribed to some other Groups, which are
    /// not known to the local database, and those are not returned.
    ///
    /// Use ``Model/isSubscribed(to:)-8ol17`` to check other Groups.
    public var subscriptions: [Group] {
        // A model may be additionally subscribed to any special address
        // except from All Nodes.
        let subscribableSpecialGroups = Group.specialGroups
            .filter { $0 != .allNodes }
        let groups = parentElement?.parentNode?.meshNetwork?.groups ?? []
        let result = (groups + subscribableSpecialGroups)
            .filter { subscribe.contains($0.groupAddress) }
        // Models on the primary Element are always subscribed to the All Nodes
        // address.
        return (parentElement?.isPrimary ?? false) ? result + [.allNodes] : result
    }
    /// The configuration of this Model's publication.
    public private(set) var publish: Publish?
    /// An array of Application Key indexes to which this model is bound.
    internal private(set) var bind: [KeyIndex]
    
    /// The model message handler. This is non-`nil` for supported local Models
    /// and `nil` for Models of remote Nodes.
    public let delegate: ModelDelegate?
    
    /// Parent Element.
    public internal(set) weak var parentElement: Element?
    
    internal init(modelId: UInt32) {
        self.modelId   = modelId
        self.subscribe = []
        self.bind      = []
        self.delegate  = nil
    }
    
    internal init(copy model: Model,
                  andTruncateTo applicationKeys: [ApplicationKey], nodes: [Node], groups: [Group]) {
        self.modelId = model.modelId
        self.bind = model.bind.filter { keyIndex in
            applicationKeys.contains { $0.index == keyIndex }
        }
        self.subscribe = model.subscribe.filter { address in
            groups.contains { $0.groupAddress == address }
        }
        // No need to set the delegate for copying.
        self.delegate = nil
        
        // Copy the Publish object if:
        // - it exists,
        // - is configured to use one of the exported Application Keys,
        // - the destination address is an exported Node, an exported Group, or special group.
        if let publish = model.publish, applicationKeys.contains(where: { $0.index == publish.index }) {
            let publishAddress = publish.publicationAddress.address
            guard publishAddress.isSpecialGroup ||
                 (publishAddress.isUnicast && nodes.contains(where: { $0.contains(elementWithAddress: publishAddress) })) ||
                 (publishAddress.isGroup && groups.contains(where: { $0.groupAddress == publish.address })) else {
                return
            }
            self.publish = publish
        }
    }
    
    internal convenience init(sigModelId: UInt16) {
        self.init(modelId: UInt32(sigModelId))
    }
    
    internal convenience init(vendorModelId: UInt16, companyId: UInt16) {
        let modelId = (UInt32(companyId) << 16) | UInt32(vendorModelId)
        self.init(modelId: modelId)
    }
    
    internal init(modelId: UInt32, delegate: ModelDelegate) {
        self.modelId   = modelId
        self.subscribe = []
        self.bind      = []
        self.delegate  = delegate
    }
    
    public convenience init(vendorModelId: UInt16, companyId: UInt16, delegate: ModelDelegate) {
        let modelId = (UInt32(companyId) << 16) | UInt32(vendorModelId)
        self.init(modelId: modelId, delegate: delegate)
    }
    
    public convenience init(sigModelId: UInt16, delegate: ModelDelegate) {
        self.init(modelId: UInt32(sigModelId), delegate: delegate)
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
                                                       debugDescription: "Model ID must be 4-character hexadecimal string.")
            }
            self.modelId = UInt32(modelId)
        } else {
            guard let modelId = UInt32(hex: modelIdString) else {
                throw DecodingError.dataCorruptedError(forKey: .modelId, in: container,
                                                       debugDescription: "Vendor Model ID must be 8-character hexadecimal string.")
            }
            self.modelId = modelId
        }
        self.subscribe = try container.decode([String].self, forKey: .subscribe)
        try subscribe.forEach {
            guard let meshAddress = MeshAddress(hex: $0) else {
                throw DecodingError.dataCorruptedError(forKey: .subscribe, in: container,
                                                       debugDescription: "Address must be 4-character hexadecimal string or UUID.")
            }
            guard meshAddress.address.isGroup || meshAddress.address.isVirtual else {
                throw DecodingError.dataCorruptedError(forKey: .subscribe, in: container,
                                                       debugDescription: "Address must be of group or virtual type.")
            }
        }
        if let publish = try container.decodeIfPresent(Publish.self, forKey: .publish) {
            self.publish = publish
        }
        self.bind = try container.decode([KeyIndex].self, forKey: .bind)
        try bind.forEach {
            guard $0.isValidKeyIndex else {
                throw DecodingError.dataCorruptedError(forKey: .bind, in: container,
                                                       debugDescription: "Key Index must be in range 0-4095.")
            }
        }
        self.delegate = nil
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
    
    var isConfigurationServer: Bool { return modelId == UInt32(UInt16.configurationServerModelId) }
    var isConfigurationClient: Bool { return modelId == UInt32(UInt16.configurationClientModelId) }
    var isHealthServer: Bool { return modelId == UInt32(UInt16.healthServerModelId) }
    var isHealthClient: Bool { return modelId == UInt32(UInt16.healthClientModelId) }
    var isSceneClient: Bool { return modelId == UInt32(UInt16.sceneClientModelId) }
    var isRemoteProvisioningServer: Bool { return modelId == UInt32(UInt16.remoteProvisioningServerModelId) }
    var isRemoteProvisioningClient: Bool { return modelId == UInt32(UInt16.remoteProvisioningClientModelId) }
    var isDirectedForwardingConfigurationServer: Bool { return modelId == UInt32(UInt16.directedForwardingConfigurationServerModelId) }
    var isDirectedForwardingConfigurationClient: Bool { return modelId == UInt32(UInt16.directedForwardingConfigurationClientModelId) }
    var isBridgeConfigurationServer: Bool { return modelId == UInt32(UInt16.bridgeConfigurationServerModelId) }
    var isBridgeConfigurationClient: Bool { return modelId == UInt32(UInt16.bridgeConfigurationClientModelId) }
    var isPrivateBeaconServer: Bool { return modelId == UInt32(UInt16.privateBeaconServerModelId) }
    var isPrivateBeaconClient: Bool { return modelId == UInt32(UInt16.privateBeaconClientModelId) }
    var isOnDemandPrivateProxyServer: Bool { return modelId == UInt32(UInt16.onDemandPrivateProxyServerModelId) }
    var isOnDemandPrivateProxyClient: Bool { return modelId == UInt32(UInt16.onDemandPrivateProxyClientModelId) }
    var isSarConfigurationServer: Bool { return modelId == UInt32(UInt16.sarConfigurationServerModelId) }
    var isSarConfigurationClient: Bool { return modelId == UInt32(UInt16.sarConfigurationClientModelId) }
    var isOpcodesAggregatorServer: Bool { return modelId == UInt32(UInt16.opcodesAggregatorServerModelId) }
    var isOpcodesAggregatorClient: Bool { return modelId == UInt32(UInt16.opcodesAggregatorClientModelId) }
    var isLargeCompositionDataServer: Bool { return modelId == UInt32(UInt16.largeCompositionDataServerModelId) }
    var isLargeCompositionDataClient: Bool { return modelId == UInt32(UInt16.largeCompositionDataClientModelId) }
    
    /// Returns whether the access layer security on the Model shall use the Device Key.
    var requiresDeviceKey: Bool {
        return isConfigurationServer                   || isConfigurationClient                   ||
               isRemoteProvisioningServer              || isRemoteProvisioningClient              ||
               isDirectedForwardingConfigurationServer || isDirectedForwardingConfigurationClient ||
               isBridgeConfigurationServer             || isBridgeConfigurationClient             ||
               isPrivateBeaconServer                   || isPrivateBeaconClient                   ||
               isOnDemandPrivateProxyServer            || isOnDemandPrivateProxyClient            ||
               isSarConfigurationServer                || isSarConfigurationClient                ||
               isLargeCompositionDataServer            || isLargeCompositionDataClient
    }
    
    /// Returns whether the access layer security on the Model can use the Device Key.
    var supportsDeviceKey: Bool {
        return requiresDeviceKey || isOpcodesAggregatorServer || isOpcodesAggregatorClient
    }
    
}

internal extension Model {
    
    /// Copies the properties from the given Model.
    ///
    /// - parameter model: The Model to copy from.
    func copy(from model: Model) {
        bind = model.bind
        publish = model.publish
        subscribe = model.subscribe
    }
    
    /// Sets the given array of Application Key Indexes as bound keys.
    ///
    /// - parameter applicationKeyIndexes: The Application Key indexes to set.
    func set(boundApplicationKeysWithIndexes applicationKeyIndexes: [KeyIndex]) {
        bind = applicationKeyIndexes.sorted()
        parentElement?.parentNode?.meshNetwork?.timestamp = Date()
    }
    
    /// Adds the given Application Key Index to the bound keys.
    ///
    /// - parameter applicationKeyIndex: The Application Key index to bind.
    func bind(applicationKeyWithIndex applicationKeyIndex: KeyIndex) {
        guard !bind.contains(applicationKeyIndex) else {
            return
        }
        bind.append(applicationKeyIndex)
        bind.sort()
        parentElement?.parentNode?.meshNetwork?.timestamp = Date()
    }
    
    /// Removes the Application Key binding to with the given Key Index
    /// and clears the publication, if it was set to use the same key.
    ///
    /// - parameter applicationKeyIndex: The Application Key index to unbind.
    func unbind(applicationKeyWithIndex applicationKeyIndex: KeyIndex) {
        guard let index = bind.firstIndex(of: applicationKeyIndex) else {
            return
        }
        bind.remove(at: index)
        // If this Application Key was used for publication,
        // the publication has been cancelled.
        if let publish = publish, publish.index == applicationKeyIndex {
            self.publish = nil
        }
        parentElement?.parentNode?.meshNetwork?.timestamp = Date()
    }
    
    /// Sets the publication to the given object.
    ///
    /// - parameter publish: The publication object.
    func set(publication publish: Publish) {
        self.publish = publish
        parentElement?.parentNode?.meshNetwork?.timestamp = Date()
    }
    
    /// Clears the publication data.
    func clearPublication() {
        publish = nil
        parentElement?.parentNode?.meshNetwork?.timestamp = Date()
    }
    
    /// Adds the given Group to the list of subscriptions.
    ///
    /// - parameter group: The new Group to be added.
    func subscribe(to group: Group) {
        let address = group.address.hex
        if !subscribe.contains(address) {
            subscribe.append(address)
            parentElement?.parentNode?.meshNetwork?.timestamp = Date()
        }
    }
    
    /// Removes the given Group from list of subscriptions.
    ///
    /// - parameter group: The Group to be removed.
    func unsubscribe(from group: Group) {
        let address = group.address.hex
        if let index = subscribe.firstIndex(of: address) {
            subscribe.remove(at: index)
            parentElement?.parentNode?.meshNetwork?.timestamp = Date()
        }
    }
    
    /// Removes the given Address from list of subscriptions.
    ///
    /// - parameter address: The Address to be removed.
    func unsubscribe(from address: Address) {
        let address = address.hex
        if let index = subscribe.firstIndex(of: address) {
            subscribe.remove(at: index)
            parentElement?.parentNode?.meshNetwork?.timestamp = Date()
        }
    }
    
    /// Removes all subscriptions from this Model.
    func unsubscribeFromAll() {
        subscribe.removeAll()
        parentElement?.parentNode?.meshNetwork?.timestamp = Date()
    }
    
}

extension Model: Equatable, Hashable {
    
    public static func == (lhs: Model, rhs: Model) -> Bool {
        return lhs.modelId == rhs.modelId 
            && lhs.parentElement == rhs.parentElement
            && lhs.bind == rhs.bind
            && lhs.subscribe == rhs.subscribe
            && lhs.publish == rhs.publish
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(modelId)
    }
    
}
