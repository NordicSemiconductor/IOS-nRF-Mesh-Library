//
//  PublicKeyInformationAvailability.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 20/12/2017.
//

import Foundation

enum PublicKeyInformationAvailability: UInt8 {
    case publicKeyInformationUnavailable = 0x00
    case publicKeyInformationAvailable   = 0x01
}
