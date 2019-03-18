//
//  SceneStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Dominique Rau on 18/11/2018.
//

import Foundation

public struct SceneStatusMessage {
    public var sourceAddress: Data
    public var statusCode: Data
    public var presentScene: Data
    public var targetScene: Data?;
    public var transitionSteps: UInt8?;
    public var transitionResolution: UInt8?;

//    Status Code, 1, Defined in 5.2.2.11
//    Current Scene, 2, Scene Number of a current scene.
//    Target Scene, 2, Scene Number of a target scene. (Optional)
//    Remaining Time, 1
    
    public init(withPayload aPayload: Data, andSoruceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        statusCode = Data([aPayload[0]])
        presentScene = Data([aPayload[1], aPayload[2]])
        if (aPayload.count > 3) {
            targetScene = Data([aPayload[3], aPayload[4]])
            let remainingTime = aPayload[5]
            transitionSteps = remainingTime & 0x3F;
            transitionResolution = remainingTime >> 6;
        }
    }
}
