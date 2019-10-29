//
//  MeshNodeEntry.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/03/2018.
//

import Foundation

/// This is a legacy class from nRF Mesh Provision 1.0.x library.
/// The only purpose of this class here is to allow to migrate from
/// the old data format to the new one.
internal struct MeshNodeEntry: Codable {
    
    // MARK: - Properties
    let nodeName                      : String
    let nodeId                        : Data
    let deviceKey                     : Data
    private let provisionedTimeStamp  : Date
    private let appKeys               : [Data]
    private let nodeUnicast           : Data?
    
    // MARK: -  Node composition
    private let companyIdentifier     : Data?
    private let productIdentifier     : Data?
    private let productVersion        : Data?
    private let replayProtectionCount : Data?
    private let featureFlags          : Data?
    private let elements              : [CompositionElement]?
    
    var isValid: Bool {
        return nodeUnicast != nil && UUID(hex: nodeId.hex) != nil
    }
    
    var uuid: UUID {
        return UUID(hex: nodeId.hex)!
    }
    
    var unicastAddress: Address {
        return nodeUnicast!.asUInt16
    }
    
    var appKeyIndexes: [KeyIndex] {
        return appKeys.map { $0.asUInt16 }
    }
    
    var cid: UInt16? {
        return companyIdentifier?.asUInt16
    }
    
    var pid: UInt16? {
        return productIdentifier?.asUInt16
    }
    
    var vid: UInt16? {
        return productVersion?.asUInt16
    }
    
    var crpl: UInt16? {
        return replayProtectionCount?.asUInt16
    }
    
    var features: NodeFeatures? {
        guard let featureFlags = featureFlags else {
            return nil
        }
        return NodeFeatures(rawValue: featureFlags.asUInt16)
    }
    
    var nodeElements: [Element] {
        return elements?.map { $0.element } ?? []
    }
    
    var groups: [Group] {
        return elements?.flatMap { $0.subscribedGroups } ?? []
    }
}

private extension Data {
    
    var asUInt16: UInt16 {
        return (UInt16(self[0]) << 8) | UInt16(self[1])
    }
    
}
