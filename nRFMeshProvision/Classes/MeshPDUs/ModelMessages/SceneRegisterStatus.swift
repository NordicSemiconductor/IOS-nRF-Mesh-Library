//
//  SceneRegisterStatusMessage.swift
//  nRFMeshProvision
//
//  Created by Dominique Rau on 18/11/2018.
//

import Foundation

public struct SceneRegisterStatusMessage {
    public var sourceAddress: Data
    public var statusCode: Data
    public var presentScene: Data
    public var scenes: Data?
    
    //    Status Code, 1, Defined in 5.2.2.11
    //    Current Scene, 2, Scene Number of a current scene.
    //    Scenes, variable, A list of scenes stored within an element
    
    public init(withPayload aPayload: Data, andSoruceAddress srcAddress: Data) {
        sourceAddress = srcAddress
        statusCode = Data([aPayload[0]])
        presentScene = Data([aPayload[1], aPayload[2]])
        if (aPayload.count > 3) {
            scenes = aPayload[3..<aPayload.count];
        }
    }
}
