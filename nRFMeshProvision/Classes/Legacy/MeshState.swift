//
//  MeshState.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/03/2018.
//

import Foundation

/// This is a legacy class from nRF Mesh Provision 1.0.x library.
/// The only purpose of this class here is to allow to migrate from
/// the old data format to the new one.
internal struct MeshState: Codable {
    
    // MARK: - Properties
    let name                     : String
    private let nextUnicast      : Data
    private let provisionedNodes : [MeshNodeEntry]
    private let netKey           : Data
    private let keyIndex         : Data
    private let IVIndex          : Data
    private let globalTTL        : Data
    private let unicastAddress   : Data
    private let flags            : Data
    private let appKeys          : [[String: Data]]
    
    var provisioner: Provisioner {
        return Provisioner(name: UIDevice.current.name)
    }
    
    var provisionerUnicastAddress: Address {
        return unicastAddress.asUInt16
    }
    
    var provisionerDefaultTtl: UInt8 {
        return globalTTL[0]
    }
    
    var networkKey: NetworkKey {
        let index: KeyIndex = keyIndex.asUInt16 & 0x0FFF
        let networkKey = try! NetworkKey(name: "Primary Network Key", index: index, key: netKey)
        networkKey.ivIndex.index = IVIndex.asUInt32
        networkKey.ivIndex.updateActive = flags[0] & 0x40 == 0x40
        networkKey.phase = flags[0] & 0x80 == 0x80 ? .finalizing : .normalOperation
        return networkKey
    }
    
    func applicationKeys(boundTo networkKey: NetworkKey) -> [ApplicationKey] {
        var keys: [ApplicationKey] = []
        appKeys.forEach { map in
            if let entry = map.first,
               let key = try? ApplicationKey(name: entry.key,
                                             index: KeyIndex(keys.count),
                                             key: entry.value,
                                             boundTo: networkKey) {
                keys.append(key)
            }
        }
        return keys
    }
    
    var groups: [Group] {
        return provisionedNodes.flatMap { $0.groups }
    }
    
    func nodes(provisionedUsingNetworkKey networkKey: NetworkKey) -> [Node] {
        var nodes: [Node] = []
        provisionedNodes.forEach { old in
            if old.isValid {
                let node = Node(name: old.nodeName, uuid: old.uuid,
                                deviceKey: old.deviceKey,
                                andAssignedNetworkKey: networkKey,
                                andAddress: old.unicastAddress)
                node.appKeys = old.appKeyIndexes.map { Node.NodeKey(index: $0, updated: false) }
                node.companyIdentifier = old.cid
                node.productIdentifier = old.pid
                node.versionIdentifier = old.vid
                node.minimumNumberOfReplayProtectionList = old.crpl
                node.features = old.features
                node.set(elements: old.nodeElements)
                nodes.append(node)
            }
        }
        return nodes
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
