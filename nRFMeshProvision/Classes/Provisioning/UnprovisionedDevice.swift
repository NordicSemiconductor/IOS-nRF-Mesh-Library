//
//  UnprovisionedDevice.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

public protocol ProvisioningDelegate {
    
    /// Callback called whenever the provisioning status changes.
    ///
    /// - parameter unprovisionedDevice: The device which state has changed.
    /// - parameter state:               The completed provisioning state.
    func provisioningState(of unprovisionedDevice: UnprovisionedDevice, didChangeTo state: ProvisionigState)
    
}

public class UnprovisionedDevice: NSObject {
    /// The provisioning delegate will receive provisioning state updates.
    public var provisioningDelegate: ProvisioningDelegate?
    /// Returns the human-readable name of the device.
    public let name: String?
    /// Returns the Mesh Beacon UUID of an Unprovisioned Device.
    public let uuid: UUID
    /// Information that points to out-of-band (OOB) information
    /// needed for provisioning.
    public let oobInformation: OobInformation
    
    public init?(advertisementData: [String : Any]) {
        // An Unprovisioned Device must advertise with UUID and OOB Information.
        guard let cbuuid  = advertisementData.unprovisionedDeviceUUID,
              let oobInfo = advertisementData.oobInformation else {
                return nil
        }
        self.name = advertisementData.localName
        self.uuid = cbuuid.uuid
        self.oobInformation = oobInfo
    }
    
}
