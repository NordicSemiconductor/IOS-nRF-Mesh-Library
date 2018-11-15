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
    func receivedModelAppStatus(_ modelAppStatusData: ModelAppStatusMessage)
    func receivedModelPublicationStatus(_ modelPublicationStatusData: ModelPublicationStatusMessage)
    func receivedModelSubsrciptionStatus(_ modelSubscriptionStatusData: ModelSubscriptionStatusMessage)
    func receivedDefaultTTLStatus(_ defaultTTLStatusData: DefaultTTLStatusMessage)
    func receivedNodeResetStatus(_ resetStatusData: NodeResetStatusMessage)
    func configurationSucceeded()
    
    // Generic model
    func receivedGenericOnOffStatusMessage(_ status: GenericOnOffStatusMessage)
    func receivedGenericLevelStatusMessage(_ status: GenericLevelStatusMessage)
    func receivedLightLightnessStatusMessage(_ status: LightLightnessStatusMessage)
    func receivedLightCtlStatusMessage(_ status: LightCtlStatusMessage)
    func receivedLightHslStatusMessage(_ status: LightHslStatusMessage)
    
    // Scene model
    func receivedSceneStatusMessage(_ status: SceneStatusMessage);
    func receivedSceneRegisterStatusMessage(_ status: SceneRegisterStatusMessage);
    
    // Vendor model
    func receivedVendorModelStatusMessage(_ status: VendorModelStatusMessage)
    
    // Sent for unacknowledged messages
    func sentGenericOnOffSetUnacknowledged(_ destinationAddress: Data)
    func sentGenericLevelSetUnacknowledged(_ destinationAddress: Data)
    
    func sentLightLightnessSetUnacknowledged(_ destinationAddress: Data)
    func sentLightCtlSetUnacknowledged(_ destinationAddress: Data)
    func sentLightHslSetUnacknowledged(_ destinationAddress: Data)
    
    func sentSceneStoreUnacknowledged(_ destinationAddress: Data)
    func sentSceneDeleteUnacknowledged(_ destinationAddress: Data)
    func sentSceneRecallUnacknowledged(_ destinationAddress: Data)
    
    func sentVendorModelUnacknowledged(_ destinationAddress: Data)
}
