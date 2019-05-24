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
    
    /// Returns the Unprovisioned Device's UUID or `nil` if such value not be parsed.
    /// This value is taken from the Service Data with Mesh Provisioning Service
    /// UUID. The first 16 bytes are the converted to CBUUID.
    var unprovisionedDeviceUUID: CBUUID? {
        guard let serviceData = self[CBAdvertisementDataServiceDataKey] as? [CBUUID : Data],
              let data = serviceData[MeshProvisioningService.uuid] else {
                return nil
        }
        guard data.count == 18 else {
            return nil
        }
        
        return CBUUID(data: data.subdata(in: 0 ..< 16))
    }
    
    /// Returns the Unprovisioned Device's OOB information or `nil` if such
    /// value not be parsed.
    /// This value is taken from the Service Data with Mesh Provisioning Service
    /// UUID. The last 2 bytes are parsed and returned as `OobInformation`.
    var oobInformation: OobInformation? {
        guard let serviceData = self[CBAdvertisementDataServiceDataKey] as? [CBUUID : Data],
              let data = serviceData[MeshProvisioningService.uuid] else {
                return nil
        }
        guard data.count == 18 else {
            return nil
        }
        
        let rawValue: UInt16 = data.convert(offset: 16)
        return OobInformation(rawValue: rawValue)
    }
    
    /// Returns the Network ID from a packet of a provisioned Node
    /// with Proxy capabilities, or `nil` if such value not be parsed.
    var networkId: Data? {
        guard let serviceData = self[CBAdvertisementDataServiceDataKey] as? [CBUUID : Data],
              let data = serviceData[MeshProxyService.uuid] else {
                return nil
        }
        guard data.count == 9, data[0] == 0x00 else {
            return nil
        }
        return data.subdata(in: 1..<9)
    }
    
    var nodeIdentity: (hash: Data, random: Data)? {
        guard let serviceData = self[CBAdvertisementDataServiceDataKey] as? [CBUUID : Data],
            let data = serviceData[MeshProxyService.uuid] else {
                return nil
        }
        guard data.count == 17, data[0] == 0x01 else {
            return nil
        }
        return (hash: data.subdata(in: 1..<9), random: data.subdata(in: 9..<17))
    }
}

public extension CBUUID {
    
    /// Converts teh CBUUID to foundation UUID.
    var uuid: UUID {
        return self.data.withUnsafeBytes { UUID(uuid: $0.load(as: uuid_t.self)) }
    }
    
}
