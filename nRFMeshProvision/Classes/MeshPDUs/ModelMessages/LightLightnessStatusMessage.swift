//
//  LightLightnessStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Dominique Rau on 18/11/2018.
//

import Foundation

public struct LightLightnessStatusMessage {
    public var sourceAddress: Data
    public var presentLightness: Data
    public var targetLightness: Data?;
    public var transitionSteps: UInt8?;
    public var transitionResolution: UInt8?;
    
    
    public init(withPayload aPayload: Data, andSoruceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        presentLightness = Data([aPayload[0], aPayload[1]])
        if (aPayload.count > 2) {
            targetLightness = Data([aPayload[2], aPayload[3]])
            let remainingTime = aPayload[4]
            transitionSteps = remainingTime & 0x3F;
            transitionResolution = remainingTime >> 6;
        }
    }
}




