//
//  InviteCapabilities.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 01/08/2018.
//

import Foundation

public struct InviteCapabilities {
    let elementCount: Int
    let algorithm: ProvisioningAlgorithm
    let publicKeyAvailability: PublicKeyInformationAvailability
    let staticOOBAvailability: StaticOutOfBoundInformationAvailability
    let outputOOBSize: UInt8
    let inputOOBSize: UInt8
    let supportedInputOOBActions: [InputOutOfBoundActions]
    let supportedOutputOOBActions: [OutputOutOfBoundActions]
}
