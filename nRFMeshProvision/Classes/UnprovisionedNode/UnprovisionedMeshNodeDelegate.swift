//
//  UnprovisionedMeshNodeDelegate.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 20/12/2017.
//

import Foundation

public protocol UnprovisionedMeshNodeDelegate {
    func nodeDidCompleteDiscovery(_ aNode: UnprovisionedMeshNode)
    func nodeRequiresUserInput(_ aNode: UnprovisionedMeshNode, completionHandler aHandler: @escaping (String) -> (Void))
    func nodeShouldDisconnect(_ aNode: UnprovisionedMeshNode)
    func nodeProvisioningCompleted(_ aNode: UnprovisionedMeshNode)
    func nodeProvisioningFailed(_ aNode: UnprovisionedMeshNode, withErrorCode anErrorCode: ProvisioningErrorCodes)
}
