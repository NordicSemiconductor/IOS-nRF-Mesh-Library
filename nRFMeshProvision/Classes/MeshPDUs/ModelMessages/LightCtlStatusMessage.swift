//
//  LightCtlStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Dominique Rau on 18/11/2018.
//

import Foundation

public struct LightCtlStatusMessage {
    public var sourceAddress: Data
    public var presentLightness: Data
    public var presentTemperature: Data
    public var targetLightness: Data?;
    public var targetTemperature: Data?;
    public var transitionSteps: UInt8?;
    public var transitionResolution: UInt8?;
    
    
    public init(withPayload aPayload: Data, andSoruceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        presentLightness = Data([aPayload[0], aPayload[1]])
        presentTemperature = Data([aPayload[2], aPayload[3]])
        if (aPayload.count > 4) {
            targetLightness = Data([aPayload[4], aPayload[5]])
            targetTemperature = Data([aPayload[6], aPayload[7]])
            let remainingTime = aPayload[8]
            transitionSteps = remainingTime & 0x3F;
            transitionResolution = remainingTime >> 6;
        }
    }
}
