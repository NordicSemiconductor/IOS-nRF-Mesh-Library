//
//  UnprovisionedDeviceBeacon.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 31/05/2019.
//

import Foundation
import CoreBluetooth

internal struct UnprovisionedDeviceBeacon: BeaconPdu {
    let pdu: Data
    let beaconType: BeaconType = .unprovisionedDevice
    
    /// Device UUID uniquely identifying this device.
    let deviceUuid: UUID
    /// The OOB Information field is used to help drive the provisioning
    /// process by indicating the availability of OOB data, such as
    /// a public key of the device.
    let oob: OobInformation
    /// Hash of the associated URI advertised with the URI AD Type.
    let uriHash: Data?
    
    /// Creates Unprovisioned Device beacon PDU object from received PDU.
    ///
    /// - parameter pdu: The data received from mesh network.
    /// - returns: The beacon object, or `nil` if the data are invalid.
    init?(decode pdu: Data) {
        self.pdu = pdu
        guard pdu.count >= 19, pdu[0] == 0 else {
            return nil
        }
        let cbuuid = CBUUID(data: pdu.subdata(in: 1..<17))
        deviceUuid = cbuuid.uuid
        oob = OobInformation(data: pdu, offset: 17)
        if pdu.count == 23 {
            uriHash = pdu.dropFirst(19)
        } else {
            uriHash = nil
        }
    }
}

internal extension UnprovisionedDeviceBeacon {
    
    /// This method goes over all Network Keys in the mesh network and tries
    /// to parse the beacon.
    ///
    /// - parameter pdu:         The received PDU.
    /// - parameter meshNetwork: The mesh network for which the PDU should be decoded.
    /// - returns: The beacon object.
    static func decode(_ pdu: Data, for meshNetwork: MeshNetwork) -> UnprovisionedDeviceBeacon? {
        guard pdu.count > 1 else {
            return nil
        }
        let beaconType = BeaconType(rawValue: pdu[0])
        switch beaconType {
        case .some(.unprovisionedDevice):
            return UnprovisionedDeviceBeacon(decode: pdu)
        default:
            return nil
        }
    }
    
}

extension UnprovisionedDeviceBeacon: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "Unprovisioned Device Beacon (UUID: \(deviceUuid.uuidString), OOB Info: \(oob), URI hash: \(uriHash?.hex ?? "None"))"
    }
    
}
