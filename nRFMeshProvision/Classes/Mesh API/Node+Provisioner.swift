//
//  Node+Provisioner.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 26/06/2019.
//

import Foundation

public extension Node {

    /// Returns whether the Node belongs to one of the Provisioners
    /// of the mesh network.
    var isProvisioner: Bool {
        return meshNetwork?.hasProvisioner(with: uuid) ?? false
    }
    
    /// Returns whether the Node belongs to the main Provisioner.
    /// The main Provisioner will be used to perform all
    /// provisioning and communication on this device. Every device
    /// should use a different Provisioner to set up devices in the
    /// same mesh network to avoid conflicts with addressing nodes.
    var isLocalProvisioner: Bool {
        let localProvisionerUuid = meshNetwork?.localProvisioner?.uuid
        return uuid == localProvisionerUuid
    }
    
    /// The Provisioner that this Node belongs to, or `nil`
    /// if it's not a Provisioner's Node.
    var provisioner: Provisioner? {
        return meshNetwork?.provisioners.first {
            $0.uuid == uuid
        }
    }
    
}
