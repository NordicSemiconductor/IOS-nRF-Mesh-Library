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

/// The Group object represents a user-defined group of Nodes,
/// identified by Group Address or Virtual Label.
///
/// A group may be given a human-readable name.
///
/// In Mesh Configuration Database a Group may have a parent Group,
/// but this is not reflected in the Mesh Profile specification. Groups
/// cannot form circle relationships.
public class Group: Codable {
    internal weak var meshNetwork: MeshNetwork?
    
    private var groupName: String
    /// UTF-8 human-readable name of the Group.
    public var name: String {
        get {
            return groupName
        }
        set {
            if !address.address.isSpecialGroup {
                groupName = newValue
            }
        }
    }
    /// The address of the group.
    public let address: MeshAddress
    
    /// The address property contains a 4-character hexadecimal
    /// string from 0xC000 to 0xFEFF or a 32-character hexadecimal
    /// string of virtual label UUID, and is the address of the group.
    internal let groupAddress: String
    /// The parentAddress property contains a 4-character hexadecimal
    /// string or a 32-character hexadecimal string and represents
    /// an address of a parent Group in which this group is included.
    /// The value of "0000" indicates that the group is not included
    /// in another group (i.e., the group has no parent).
    internal var parentAddress: String = "0000"
    
    /// The parent Group of this Group, or `nil`, if the Group has no parent.
    /// The Group must be added to a mesh network in order to get or set the
    /// parent Group. The parent Group must be added to the network prior to
    /// the child.
    public var parent: Group? {
        get {
            guard let meshNetwork = meshNetwork else {
                return nil
            }
            if parentAddress == "0000" {
                return nil
            }
            return meshNetwork.groups.first {
                $0.groupAddress == parentAddress
            }
        }
        set {
            guard let parent = newValue else {
                parentAddress = "0000"
                return
            }
            if let meshNetwork = meshNetwork, meshNetwork.groups.contains(parent) {
                parentAddress = parent.groupAddress
            }
        }
    }
    
    public init(name: String, address: MeshAddress) throws {
        guard address.address.isGroup && !address.address.isSpecialGroup ||
              address.address.isVirtual else {
            throw MeshNetworkError.invalidAddress
        }
        self.groupName = name
        self.groupAddress = address.hex
        self.address = address
        self.parentAddress = "0000"
    }
    
    public convenience init(name: String, address: Address) throws {
        try self.init(name: name, address: MeshAddress(address))
    }
    
    private init(name: String, specialGroup: Address) {
        self.groupName = name
        self.groupAddress = specialGroup.hex
        self.address = MeshAddress(specialGroup)
        self.parentAddress = "0000"
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case groupName     = "name"
        case groupAddress  = "address"
        case parentAddress = "parentAddress"
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.groupName = try container.decode(String.self, forKey: .groupName)
        self.groupAddress = try container.decode(String.self, forKey: .groupAddress)
        guard let address = MeshAddress(hex: groupAddress) else {
            throw DecodingError.dataCorruptedError(forKey: .groupAddress, in: container,
                                                   debugDescription: "Invalid Group address: \(groupAddress).")
        }
        guard address.address.isGroup || address.address.isVirtual else {
            throw DecodingError.dataCorruptedError(forKey: .groupAddress, in: container,
                                                   debugDescription: "Not a Group address: \(groupAddress).")
        }
        guard !address.address.isSpecialGroup else {
            throw DecodingError.dataCorruptedError(forKey: .groupAddress, in: container,
                                                   debugDescription: "Illegal Group address: \(groupAddress).")
        }
        self.address = address
        self.parentAddress = try container.decode(String.self, forKey: .parentAddress)
        guard let parentAddress = MeshAddress(hex: parentAddress) else {
            throw DecodingError.dataCorruptedError(forKey: .parentAddress, in: container,
                                                   debugDescription: "Invalid Group address: \(groupAddress).")
        }
        guard parentAddress.address.isUnassigned ||
              parentAddress.address.isGroup ||
              parentAddress.address.isVirtual else {
            throw DecodingError.dataCorruptedError(forKey: .parentAddress, in: container,
                                                   debugDescription: "Invalid Parent Group address: \(parentAddress).")
        }
        guard !parentAddress.address.isSpecialGroup else {
            throw DecodingError.dataCorruptedError(forKey: .parentAddress, in: container,
                                                   debugDescription: "Illegal Parent Group address: \(groupAddress).")
        }
    }
}

extension Group: Equatable, Hashable {
    
    public static func == (lhs: Group, rhs: Group) -> Bool {
        return lhs.groupAddress == rhs.groupAddress
    }
    
    public static func != (lhs: Group, rhs: Group) -> Bool {
        return lhs.groupAddress != rhs.groupAddress
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(groupAddress)
    }
    
}

public extension Group {
    /// A message sent to the All Nodes address shall be processed by the primary Element
    /// of all nodes.
    static let allNodes   = Group(name: NSLocalizedString("All Nodes", comment: ""),   specialGroup: .allNodes)
    /// A message sent to the All Relays address shall be processed by the primary Element
    /// of all nodes that have the relay functionality enabled, or by any Model subscribed
    /// to it.
    static let allRelays  = Group(name: NSLocalizedString("All Relays", comment: ""),  specialGroup: .allRelays)
    /// A message sent to the All Friends address shall be processed by the primary Element
    /// of all nodes that have the friend functionality enabled, or by any Model subscribed
    /// to it.
    static let allFriends = Group(name: NSLocalizedString("All Friends", comment: ""), specialGroup: .allFriends)
    /// A message sent to the All Proxies address shall be processed by the primary Element
    /// of all nodes that have the proxy functionality enabled, or by any Model subscribed
    /// to it.
    static let allProxies = Group(name: NSLocalizedString("All Proxies", comment: ""), specialGroup: .allProxies)
    /// Returns all special Groups supported by this version of the mesh library.
    static let specialGroups: [Group] = [.allRelays, .allFriends, .allProxies, .allNodes]
    /// Returns a special Group with the given address, or nil.
    static func specialGroup(withAddress address: Address) -> Group? {
        return specialGroups.first { $0.address.address == address }
    }
    /// Returns a special Group with the given address, or nil.
    static func specialGroup(withAddress address: MeshAddress) -> Group? {
        return specialGroup(withAddress: address.address)
    }
    
}
