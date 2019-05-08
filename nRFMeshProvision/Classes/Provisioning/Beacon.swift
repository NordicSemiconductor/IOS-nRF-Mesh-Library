//
//  Beacon.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 07/05/2019.
//

import Foundation
import CoreBluetooth

public extension Dictionary where Key == String, Value == Any {
    
    /// Returns the value under the Complete or Shortened Local Name
    /// from the advertising packet, or `nil` if such doesn't exist.
    var localName: String? {
        return self[CBAdvertisementDataLocalNameKey] as? String
    }
    
    /// Returns the Unprovisioned Device's UUID.
    /// This value is taken from the Service Data with Mesh Provisioning Service
    /// UUID. The first 16 bytes are the converted to CBUUID.
    ///
    /// - returns: The device CBUUID or `nil` if could not be parsed.
    var unprovisionedDeviceUUID: CBUUID? {
        if let serviceData = self[CBAdvertisementDataServiceDataKey] as? [CBUUID : Data],
            let data = serviceData[MeshProvisioningService.uuid] {
            guard data.count == 18 else {
                return nil
            }
            
            return CBUUID(data: data.subdata(in: 0 ..< 16))
        }
        return nil
    }
    
    /// Returns the Unprovisioned Device's OOB information.
    /// This value is taken from the Service Data with Mesh Provisioning Service
    /// UUID. The last 2 bytes are parsed and returned as `OobInformation`.
    ///
    /// - returns: The device OOB information or `nil` if could not be parsed.
    var oobInformation: OobInformation? {
        if let serviceData = self[CBAdvertisementDataServiceDataKey] as? [CBUUID : Data],
            let data = serviceData[MeshProvisioningService.uuid] {
            guard data.count == 18 else {
                return nil
            }
            
            let rawValue: UInt16 = data.convert(offset: 16)
            return OobInformation(rawValue: rawValue)
        }
        return nil
    }
    
}

public extension CBUUID {
    
    /// Converts teh CBUUID to foundation UUID.
    var uuid: UUID {
        return self.data.withUnsafeBytes { UUID(uuid: $0.load(as: uuid_t.self)) }
    }
    
}
