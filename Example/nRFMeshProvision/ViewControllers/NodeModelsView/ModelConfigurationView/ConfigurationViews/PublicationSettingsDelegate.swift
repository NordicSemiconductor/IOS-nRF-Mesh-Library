//
//  PublicationSettingsDelegate.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 03/08/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation

protocol PublicationSettingsDelegate {
    func didDisablePublication()
    func didSavePublicatoinConfiguration(withAddress anAddress: Data,
                                         appKeyIndex anAppKeyIndex: UInt8,
                                         credentialFlag aCredentialFlag: Bool,
                                         ttl aTTL: UInt8,
                                         publishPeriod aPublishPeriod: UInt8,
                                         retransmitCount aRetransmitCoutn: UInt8,
                                         retransmitIntervalSteps aRetransmitIntervalStep: UInt8
                                         )
}
