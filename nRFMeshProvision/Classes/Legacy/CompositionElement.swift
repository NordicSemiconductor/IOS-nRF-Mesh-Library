//
//  CompositionElement.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 04/04/2018.
//

import Foundation

/// This is a legacy class from nRF Mesh Provision 1.0.x library.
/// The only purpose of this class here is to allow to migrate from
/// the old data format to the new one.
internal struct CompositionElement: Codable {
    
    // MARK: - Properties
    private let location                    : Data
    private let sigModelCount               : Int
    private let vendorModelCount            : Int
    private let sigModels                   : [Data]
    private let vendorModels                : [Data]
    private let allModels                   : [Data]
    private let modelKeyBindings            : [Data: Data]
    private let modelPublishAddress         : [Data: Data]
    private let modelSubscriptionAddresses  : [Data: [Data]]
    
    func groups(for data: Data) -> [Group] {
        return modelSubscriptionAddresses[data]?.compactMap {
            let address: Address = $0.asUInt16
            return try? Group(name: "Group 0x\(address.hex)", address: address)
        } ?? []
    }
    
    var subscribedGroups: [Group] {
        return modelSubscriptionAddresses.flatMap { data in
            groups(for: data.key)
        }
    }
    
    var element: Element {
        let element = Element(location: Location(rawValue: location.asUInt16) ?? .unknown)
        sigModels.forEach {
            let model = Model(sigModelId: $0.asUInt16)
            if let binding = modelKeyBindings[$0] {
                model.bind(applicationKeyWithIndex: binding.asUInt16)
                
                if let publication = modelPublishAddress[$0] {
                    model.set(publication: Publish(to: MeshAddress(publication.asUInt16),
                                                   usingApplicationKeyWithKeyIndex: binding.asUInt16,
                                                   usingFriendshipMaterial: false, ttl: 0xFF,
                                                   periodSteps: 0,
                                                   periodResolution: .hundredsOfMilliseconds,
                                                   retransmit: Publish.Retransmit()))
                }
            }
            groups(for: $0).forEach { group in model.subscribe(to: group )}
            element.add(model: model)
        }
        vendorModels.forEach { element.add(model: Model(vendorModelId: $0.asUInt32)) }
        return element
    }
}

private extension Data {
    
    var asUInt16: UInt16 {
        return (UInt16(self[0]) << 8) | UInt16(self[1])
    }
    
    var asUInt32: UInt32 {
        return (UInt32(self[0]) << 24) | (UInt32(self[1]) << 16) | (UInt32(self[2]) << 8) | UInt32(self[3])
    }
    
}
