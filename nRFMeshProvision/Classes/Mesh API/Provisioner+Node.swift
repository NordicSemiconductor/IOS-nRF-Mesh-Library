//
//  Provisioner+Node.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 04/06/2019.
//

import Foundation

public extension Provisioner {
    
    /// The Unicast Address of the Provisioner.
    ///
    /// The Provisioner must be added to a mesh network and
    /// must have a Unicast Address assigned, otherwise `nil`
    /// is returned instead.
    var unicastAddress: Address? {
        return meshNetwork?.node(for: self)?.unicastAddress
    }
    
    /// The Provisioner's Node, if such exists, otherwise `nil`.
    var node: Node? {
        return meshNetwork?.node(for: self)
    }
    
    /// Whether the Provisioner can send and receive mesh messages.
    ///
    /// To have configuration capabilities the Provisioner must have
    /// a Unicast Address assigned, therefore it is a Node in the
    /// network.
    var hasConfigurationCapabilities: Bool {
        return node != nil
    }
    
    /// Whether the Provisioner is the one currently set
    /// as a local Provisioner.
    var isLocal: Bool {
        return meshNetwork?.isLocalProvisioner(self) ?? false
    }
    
}
