//
//  MeshNetwork+Groups.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 16/07/2019.
//

import Foundation

public extension MeshNetwork {
    
    /// Returns the Group with given Address, or 'nil` if no such was found.
    ///
    /// - parameter address: The Group Address.
    /// - returns: The Group with given Address, or `nil` if no such found.
    func group(withAddress address: MeshAddress) -> Group? {
        return groups.first { $0.address == address }
    }
    
    /// Adds a new Group to the network.
    ///
    /// If the mesh network already contains a Group with the same address,
    /// this method throws an error.
    ///
    /// - parameter group: The Group to be added.
    /// - throws: This method throws an error if a Group with the same address
    ///           already exists in the mesh network.
    func add(group: Group) throws {
        guard !groups.contains(group) else {
            throw MeshModelError.groupAlreadyExists
        }
        groups.append(group)
        group.meshNetwork = self
    }
    
    /// Removes the given Group from the network.
    ///
    /// The Group must not be in use, i.e. it may not be a parent of
    /// another Group.
    ///
    /// - parameter group: The Group to be removed.
    /// - throws: This method throws `MeshModelError.groupInUse` when the
    //            Group is in use in this mesh network.
    func remove(group: Group) throws {
        if group.isUsed {
            throw MeshModelError.groupInUse
        }
        if let index = groups.firstIndex(of: group) {
            groups.remove(at: index).meshNetwork = nil
        }
    }
    
}
