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
    
    var features: NodeFeaturesState? {
        guard let featureFlags = featureFlags else {
            return nil
        }
        return NodeFeaturesState(mask: featureFlags.asUInt16)
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
