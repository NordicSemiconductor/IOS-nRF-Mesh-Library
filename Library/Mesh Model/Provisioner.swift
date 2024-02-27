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

/// Representation of a Provisioner in the mesh network.
///
/// A Provisioner is an entity that is able to provision other device to
/// the mesh network by assigning them Unicast Addresses and providing
/// a Network Key in a secure way. A Provisioner with a Unicast Address
/// assigned may also configure devices and becomes a Node of a network
/// on its own.
///
/// Each Provisioner has assigned 3 ranges:
/// * Unicast Address range - set of Unicast Addresses which may assign to new
///   Nodes during provisioning,
/// * Group Address range - set of Group Addresses which the Provisioner may use
///   to define new groups.
/// * Scene range - set of Scene numbers which it may use to define new scenes.
///
/// The Provisioner should not assign addresses from outside of its ranges to avoid
/// conflicts with other Provisioners.
public class Provisioner: Codable {
    internal weak var meshNetwork: MeshNetwork?
    
    /// Provisioner's UUID. If the Provisioner has a corresponding Node,
    /// the Node's UUID will be equal to this one.
    public let uuid: UUID
    /// UTF-8 string, which should be a human readable name of the Provisioner.
    public var name: String {
        didSet {
            if let network = meshNetwork, let node = network.node(for: self) {
                node.name = name
            }
        }
    }
    /// An array of unicast range objects.
    public internal(set) var allocatedUnicastRange: [AddressRange]
    /// An array of group range objects.
    public internal(set) var allocatedGroupRange:   [AddressRange]
    /// An array of scene range objects.
    public internal(set) var allocatedSceneRange:   [SceneRange]
    
    public init(name: String,
                uuid: UUID,
                allocatedUnicastRange: [AddressRange],
                allocatedGroupRange:   [AddressRange],
                allocatedSceneRange:   [SceneRange]) {
        self.name = name
        self.uuid = uuid
        self.allocatedUnicastRange = allocatedUnicastRange.merged()
        self.allocatedGroupRange   = allocatedGroupRange.merged()
        self.allocatedSceneRange   = allocatedSceneRange.merged()
    }
    
    public convenience init(name: String,
                            allocatedUnicastRange: [AddressRange],
                            allocatedGroupRange:   [AddressRange],
                            allocatedSceneRange:   [SceneRange]) {
        self.init(name: name,
                  uuid: UUID(),
                  allocatedUnicastRange: allocatedUnicastRange,
                  allocatedGroupRange:   allocatedGroupRange,
                  allocatedSceneRange:   allocatedSceneRange
        )
    }
    
    public convenience init(name: String) {
        self.init(name: name,
                  uuid: UUID(),
                  allocatedUnicastRange: [AddressRange.allUnicastAddresses],
                  allocatedGroupRange:   [AddressRange.allGroupAddresses],
                  allocatedSceneRange:   [SceneRange.allScenes]
        )
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case uuid = "UUID"
        case name = "provisionerName"
        case allocatedUnicastRange
        case allocatedGroupRange
        case allocatedSceneRange
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        
        // In version 3.0 of this library the Provisioner's UUID format has changed
        // from 32-character hexadecimal String to standard UUID format (RFC 4122).
        uuid = try container.decode(UUID.self, forKey: .uuid,
                                    orConvert: MeshUUID.self, forKey: .uuid, using: { $0.uuid })
        
        allocatedUnicastRange = try container.decode([AddressRange].self, forKey: .allocatedUnicastRange).merged()
        allocatedGroupRange = try container.decode([AddressRange].self, forKey: .allocatedGroupRange).merged()
        allocatedSceneRange = try container.decode([SceneRange].self, forKey: .allocatedSceneRange).merged()
    }
}

// MARK: - Operators

extension Provisioner: Equatable {
    
    public static func == (lhs: Provisioner, rhs: Provisioner) -> Bool {
        return lhs.uuid == rhs.uuid
            && lhs.name == rhs.name
            && lhs.allocatedUnicastRange == rhs.allocatedUnicastRange
            && lhs.allocatedGroupRange == rhs.allocatedGroupRange
            && lhs.allocatedSceneRange == rhs.allocatedSceneRange
    }
    
}
