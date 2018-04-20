//
//  UnprovisionedMeshNodeLoggingDelegate.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 19/01/2018.
//

import Foundation

public protocol UnprovisionedMeshNodeLoggingDelegate {
    func logDisconnect()
    func logConnect()
    func logDiscoveryStarted()
    func logDiscoveryCompleted()
    func logSwitchedToProvisioningState(withMessage aMessage: String)
    func logUserInputRequired()
    func logUserInputCompleted(withMessage aMessage: String)
    func logGenerateKeypair(withMessage aMessage: String)
    func logCalculatedECDH(withMessage aMessage: String)
    func logGeneratedProvisionerRandom(withMessage aMessage: String)
    func logReceivedDeviceRandom(withMessage aMessage: String)
    func logGeneratedProvisionerConfirmationValue(withMessage aMessage: String)
    func logReceivedDeviceConfirmationValue(withMessage aMessage: String)
    func logGenratedProvisionInviteData(withMessage aMessage: String)
    func logGeneratedProvisioningStartData(withMessage aMessage: String)
    func logReceivedCapabilitiesData(withMessage aMessage: String)
    func logReceivedDevicePublicKey(withMessage aMessage: String)
    func logProvisioningSucceeded()
    func logProvisioningFailed(withMessage aMessage: String)
}
