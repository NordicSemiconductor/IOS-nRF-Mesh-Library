//
//  Group.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 10/07/2019.
//

import Foundation

public class Group: Codable {
    internal weak var meshNetwork: MeshNetwork?
    
    /// UTF-8 human-readable name of the Group.
    public var name: String
    /// The address property contains a 4-character hexadecimal
    /// string from 0xC000 to 0xFEFF or a 32-character hexadecimal
    /// string of virtual label UUUID, and is the address of the group.
    internal let _address: String
    /// The address of the group.
    public lazy var address: MeshAddress = MeshAddress(hex: _address)!
    /// The parentAddress property contains a 4-character hexadecimal
    /// string or a 32-character hexadecimal string and represents
    /// an address of a parent Group in which this group is included.
    /// The value of "0000" indicates that the group is not included
    /// in another group (i.e., the group has no parent).
    internal var _parentAddress: String = "0000"
    /// The parent Group of this Group, or `nil`, if the Group has no parent.
    /// The Group must be added to a mesh network in order to get or set the
    /// parent Group. The parent Group must be added to the network prior to
    /// the child.
    public var parent: Group? {
        get {
            guard let meshNetwork = meshNetwork else {
                return nil
            }
            if _parentAddress == "0000" {
                return nil
            }
            return meshNetwork.groups.first {
                $0._address == _parentAddress
            }
        }
        set {
            guard let parent = newValue else {
                _parentAddress = "0000"
                return
            }
            if let meshNetwork = meshNetwork, meshNetwork.groups.contains(parent) {
                _parentAddress = parent._address
            }
        }
    }
    
    public init(name: String, address: MeshAddress) throws {
        guard address.address.isGroup && !address.address.isSpecialGroup ||
              address.address.isVirtual else {
            throw MeshNetworkError.invalidAddress
        }
        self.name = name
        self._address = address.hex
        self._parentAddress = "0000"
    }
    
    public convenience init(name: String, address: Address) throws {
        try self.init(name: name, address: MeshAddress(address))
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case name
        case _address       = "address"
        case _parentAddress = "parentAddress"
    }
}

extension Group: Equatable {
    
    public static func == (lhs: Group, rhs: Group) -> Bool {
        return lhs._address == rhs._address
    }
    
    public static func != (lhs: Group, rhs: Group) -> Bool {
        return lhs._address != rhs._address
    }
    
}
