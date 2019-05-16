//
//  MeshNetwork+Nodes.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 25/04/2019.
//

import Foundation

public extension MeshNetwork {    
    
    /// Returns Provisioner's node object, if such exist and the Provisioner
    /// is in the mesh network.
    ///
    /// - parameter provisioner: The provisioner which node is to be returned.
    ///                          The provisioner must be added to the network
    ///                          before calling this method, otherwise `nil` will
    ///                          be returned. Provisioners without a node assigned
    ///                          do not support configuration operations.
    /// - returns: The Provisioner's node object, or `nil`.
    func node(for provisioner: Provisioner) -> Node? {
        guard hasProvisioner(provisioner) else {
            return nil
        }
        return node(withUuid: provisioner.uuid)
    }
    
    /// Returns the newly added Node for the Unprovisioned Device object.
    ///
    /// - parameter unprovisionedDevice: The device which node is to be returned.
    /// - returns: The Node object, or `nil`, if not found.
    func node(for unprovisionedDevice: UnprovisionedDevice) -> Node? {
        return node(withUuid: unprovisionedDevice.uuid)
    }
    
    /// Returns the first found Node with given UUID.
    ///
    /// - parameter uuid: The Node UUID to look for.
    /// - returns: The Node found, or `nil` if no such exists.
    func node(withUuid uuid: UUID) -> Node? {
        return nodes.first {
            $0.uuid == uuid
        }
    }
    
}
