//
//  ProvisioningAlgorithm.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 20/12/2017.
//

import Foundation

public enum ProvisioningAlgorithm: UInt16 {
    case none                  = 0x0000
    case fipsp256EllipticCurve = 0x0001
}
