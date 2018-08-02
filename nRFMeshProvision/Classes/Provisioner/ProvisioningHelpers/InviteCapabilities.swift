//
//  InviteCapabilities.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 01/08/2018.
//

import Foundation

public class InviteCapabilities {
    public let elementCount             : Int
    public let algorithm                : ProvisioningAlgorithm
    public let publicKeyAvailability    : PublicKeyInformationAvailability
    public let staticOOBAvailability    : StaticOutOfBoundInformationAvailability
    public let outputOOBSize            : UInt8
    public let inputOOBSize             : UInt8
    public let supportedInputOOBActions : [InputOutOfBoundActions]
    public let supportedOutputOOBActions: [OutputOutOfBoundActions]
    
    init(withElementCount elementCount: Int,
         algorithm: ProvisioningAlgorithm,
         publicKeyAvailability: PublicKeyInformationAvailability,
         staticOOBAvailability: StaticOutOfBoundInformationAvailability,
         outputOOBSize: UInt8,
         inputOOBSize: UInt8,
         supportedInputOOB: [InputOutOfBoundActions],
         supportedOutputOOB: [OutputOutOfBoundActions]) {
        
        self.elementCount = elementCount
        self.algorithm = algorithm
        self.publicKeyAvailability = publicKeyAvailability
        self.staticOOBAvailability = staticOOBAvailability
        self.outputOOBSize = outputOOBSize
        self.inputOOBSize = inputOOBSize
        self.supportedInputOOBActions = supportedInputOOB
        self.supportedOutputOOBActions = supportedOutputOOB
    }
}
