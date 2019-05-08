//
//  NetworkKey+MeshNetwork.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 08/05/2019.
//

import Foundation

public extension NetworkKey {
    
    /// Returns whether the Network Key is the Primary Network Key.
    /// The Primary key is the one which Key Index is equal to 0.
    ///
    /// A Primary Network Key may not be removed from the mesh network.
    var isPrimary: Bool {
        return index == 0
    }
    
    /// Return whether the Network Key is used in the given mesh network.
    ///
    /// A Network Key must be added to Network Keys array of the network
    /// and be either a Primary Key, a key known to at least one node,
    /// or bound to an existing Application Key to be used by it.
    ///
    /// An used Network Key may not be removed from the network.
    ///
    /// - parameter meshNetwork: The mesh network to look the key in.
    /// - returns: `True` if the key is used in the given network,
    ///            `false` otherwise.
    func isUsed(in meshNetwork: MeshNetwork) -> Bool {
        let localProvisioner = meshNetwork.provisioners.first
        return meshNetwork.networkKeys.contains(self) &&
            (
                // Primary Network Key.
                isPrimary ||
                // Network Key known by at least one node (except the local Provisioner).
                meshNetwork.nodes.filter({ $0.uuid != localProvisioner?.uuid }).knows(networkKey: self) ||
                // Network Key bound to an Application Key.
                meshNetwork.applicationKeys.contains(keyBoundTo: self)
            )
    }
    
}
