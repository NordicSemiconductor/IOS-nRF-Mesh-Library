//
//  ProvisionedMeshNodeDelegate.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/02/2018.
//

import Foundation

public protocol ProvisionedMeshNodeDelegate {
    func nodeDidCompleteDiscovery(_ aNode: ProvisionedMeshNode)
    func nodeShouldDisconnect(_ aNode: ProvisionedMeshNode)
    func receivedCompositionData(_ compositionData: CompositionStatusMessage)
    func receivedAppKeyStatusData(_ appKeyStatusData: AppKeyStatusMessage)
    func receivedModelAppBindStatus(_ modelAppStatusData: ModelAppBindStatusMessage)
    func receivedModelPublicationStatus(_ modelPublicationStatusData: ModelPublicationStatusMessage)
    func configurationSucceeded()
}
