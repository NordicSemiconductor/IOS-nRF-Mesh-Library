//
//  LightHslStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Dominique Rau on 18/11/2018.
//

import Foundation

public struct LightHslStatusMessage {
    public var sourceAddress: Data
    public var presentLightness: Data
    public var presentHue: Data
    public var presentSaturation: Data
    public var transitionSteps: UInt8?;
    public var transitionResolution: UInt8?;
    
    
    public init(withPayload aPayload: Data, andSoruceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        presentLightness = Data([aPayload[0], aPayload[1]])
        presentHue = Data([aPayload[2], aPayload[3]])
        presentSaturation = Data([aPayload[4], aPayload[5]])
        if (aPayload.count > 6) {
            let remainingTime = aPayload[6]
            transitionSteps = remainingTime & 0x3F;
            transitionResolution = remainingTime >> 6;
        }
    }
}
