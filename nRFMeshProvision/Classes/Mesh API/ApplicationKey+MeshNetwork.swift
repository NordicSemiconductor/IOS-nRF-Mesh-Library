//
//  ApplicationKey+MeshNetwork.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 08/05/2019.
//

import Foundation

public extension ApplicationKey {
    
    /// Return whether the Application Key is used in the given mesh network.
    ///
    /// A Application Key must be added to Application Keys array of the network
    /// and be known to at least one node to be used by it.
    ///
    /// An used Application Key may not be removed from the network.
    ///
    /// - parameter meshNetwork: The mesh network to look the key in.
    /// - returns: `True` if the key is used in the given network,
    ///            `false` otherwise.
    func isUsed(in meshNetwork: MeshNetwork) -> Bool {
        let localProvisioner = meshNetwork.provisioners.first
        return meshNetwork.applicationKeys.contains(self) &&
               // Application Key known by at least one node.
               meshNetwork.nodes.filter({ $0.uuid != localProvisioner?.uuid }).knows(applicationKey: self)
    }
    
}
