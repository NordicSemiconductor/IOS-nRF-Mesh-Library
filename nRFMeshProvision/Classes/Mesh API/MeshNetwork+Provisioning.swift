//
//  MeshNetwork+Provisioning.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 08/05/2019.
//

import Foundation

public extension MeshNetwork {
    
    /// This method returns the Provisioning Manager that can be used
    /// to provision the given device.
    ///
    /// - parameter unprovisionedDevice: The device to be added to mes network.
    /// - parameter bearer: The Provisioning Bearer to be used for sending
    ///                     provisioning PDUs.
    /// - returns: The Provisioning manager that should be used to continue
    ///            provisioning process after identification.
    func provision(unprovisionedDevice: UnprovisionedDevice,
                   over bearer: ProvisioningBearer) -> ProvisioningManager {
        return ProvisioningManager(for: unprovisionedDevice, over: bearer, in: self)
    }
    
}
