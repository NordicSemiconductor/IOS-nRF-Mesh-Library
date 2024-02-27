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
#if os(iOS)
import UIKit
#endif

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
        #if os(OSX)
        let provisionerName = Host.current().localizedName ?? "OSX"
        #else
        let provisionerName = UIDevice.current.name
        #endif
        
        return Provisioner(name: provisionerName)
    }
    
    var provisionerUnicastAddress: Address {
        return unicastAddress.asUInt16
    }
    
    var provisionerDefaultTtl: UInt8 {
        return globalTTL[0]
    }
    
    var ivIndex: IvIndex {
        return IvIndex(index: IVIndex.asUInt32,
                       updateActive: flags[0] & 0x40 == 0x40)
    }
    
    var networkKey: NetworkKey {
        let index: KeyIndex = keyIndex.asUInt16 & 0x0FFF
        let networkKey = try! NetworkKey(name: "Primary Network Key", index: index, key: netKey)
        networkKey.phase = flags[0] & 0x80 == 0x80 ? .usingNewKeys : .normalOperation
        // The Key's minimum security cannot be guaranteed for legacy network
        // as Nodes' security level was not stored.
        networkKey.lowerSecurity()
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
                                security: .insecure,
                                andAssignedNetworkKey: networkKey,
                                andAddress: old.unicastAddress)
                node.companyIdentifier = old.cid
                node.productIdentifier = old.pid
                node.versionIdentifier = old.vid
                node.minimumNumberOfReplayProtectionList = old.crpl
                node.features = old.features
                node.set(elements: old.nodeElements)
                node.set(applicationKeysWithIndexes: old.appKeyIndexes)
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
