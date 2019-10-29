//
//  UnprovisionedDevice.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

public class UnprovisionedDevice: NSObject {
    /// Returns the human-readable name of the device.
    public var name: String?
    /// Returns the Mesh Beacon UUID of an Unprovisioned Device.
    public let uuid: UUID
    /// Information that points to out-of-band (OOB) information
    /// needed for provisioning.
    public let oobInformation: OobInformation
    
    /// Creates a basic Unprovisioned Device object.
    ///
    /// - parameter name: The optional name of the device.
    /// - parameter uuid: The UUID of the Unprovisioned Device.
    /// - parameter oobInformation: The information about OOB data.
    public init(name: String? = nil, uuid: UUID, oobInformation: OobInformation = OobInformation(rawValue: 0)) {
        self.name = name
        self.uuid = uuid
        self.oobInformation = oobInformation
    }
    
    /// Creates the Unprovisioned Device object based on the advertisement
    /// data. The Mesh UUID and OOB Information must be present in the
    /// advertisement data, otherwise `nil` is returned.
    ///
    /// - parameter advertisementData: The advertisement data deceived
    ///                                from the device during scanning.
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
