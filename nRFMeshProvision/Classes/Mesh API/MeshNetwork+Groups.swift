//
//  MeshNetwork+Groups.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 16/07/2019.
//

import Foundation

public extension MeshNetwork {
    
    /// Adds a new Group to the network.
    ///
    /// If the mesh network already contains a Group with the same address,
    /// this method does nothing.
    ///
    /// - parameter group: The Group to be added.
    func add(group: Group) {
        guard !groups.contains(group) else {
            // The Group with this address already exists.
            return
        }
        groups.append(group)
        group.meshNetwork = self
    }
    
    /// Removes the given Group from the network.
    ///
    /// The Group must not be in use in order to be removed.
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
