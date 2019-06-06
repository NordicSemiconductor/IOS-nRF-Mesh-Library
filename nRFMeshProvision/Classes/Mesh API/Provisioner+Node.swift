//
//  Provisioner+Node.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 04/06/2019.
//

import Foundation

public extension Provisioner {
    
    /// Returns the Unicast Address of the Provisioner.
    /// The Provisioner must be added to a mesh network and
    /// must have a Unicast Address assigned, otherwise `nil`
    /// is returned instead.
    var unicastAddress: Address? {
        return meshNetwork?.node(for: self)?.unicastAddress
    }
    
    /// Returns the Provisioner's Node, if such exists,
    /// otherwise `nil`.
    var node: Node? {
        return meshNetwork?.node(for: self)
    }
    
}
