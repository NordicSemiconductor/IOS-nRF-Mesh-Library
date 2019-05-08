//
//  MeshNetwork+Provisioning.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 08/05/2019.
//

import Foundation

public extension MeshNetwork {
    
    /// This method initializes the provisioning of the device.
    ///
    /// - parameter attentionTimer: This value determines for how long (in seconds) the
    ///                             device shall remain attracting human's attention by
    ///                             blinking, flashing, buzzing, etc.
    ///                             The value 0 disables Attention Timer.
    func identify(unprovisionedDevice: UnprovisionedDevice, andAttractFor attentionTimer: UInt8) {
        
    }
    
    /// This method starts the provisioning of the device.
    /// `identify(andAttractFor:)` has to be called prior to this to receive
    /// the device capabilities.
    func provision(unprovisionedDevice: UnprovisionedDevice,
                   usingAlgorithm algorithm: Algorithm,
                   publicKey: PublicKey,
                   authenticationMethod: AuthenticationMethod,
                   action: OobAction, size: UInt8) {
        
    }
    
}
