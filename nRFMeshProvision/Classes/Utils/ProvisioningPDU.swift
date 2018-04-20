//
//  ProvisioningPDU.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 19/12/2017.
//

import Foundation

public enum ProvisioningPDU: UInt8 {
    case invite         = 0x00
    case capabilities   = 0x01
    case start          = 0x02
    case publicKey      = 0x03
    case inputComplete  = 0x04
    case confirmation   = 0x05
    case random         = 0x06
    case data           = 0x07
    case complete       = 0x08
    case failed         = 0x09
}
