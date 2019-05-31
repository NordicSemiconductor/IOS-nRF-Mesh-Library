//
//  BeaconPdu.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 31/05/2019.
//

import Foundation

internal enum BeaconType: UInt8 {
    case unprovisionedDevice = 0
    case secureNetwork       = 1
}

internal protocol BeaconPdu {
    /// Raw PDU data.
    var pdu: Data { get }
    /// The beacon type.
    var beaconType: BeaconType { get }
}
