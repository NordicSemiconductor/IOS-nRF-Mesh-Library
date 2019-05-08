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
    ///                          before calling this method, otherwise nil will
    ///                          be returned. Provisioners without node assigned
    ///                          do not support configuration operations.
    /// - returns: The Provisioner's node object.
    func node(for provisioner: Provisioner) -> Node? {
        if let index = nodes.firstIndex(where: { $0.uuid == provisioner.uuid }) {
            return nodes[index]
        }
        return nil
    }
    
}
