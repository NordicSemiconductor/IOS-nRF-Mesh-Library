//
//  GenericDefaultTransitionTimeGet.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 23/08/2019.
//

import Foundation

public struct GenericDefaultTransitionTimeGet: AcknowledgedGenericMessage {
    public static let opCode: UInt32 = 0x820D
    public static let responseType: StaticMeshMessage.Type = GenericDefaultTransitionTimeStatus.self
    
    public var parameters: Data? {
        return nil
    }
    
    public init() {
        // Empty
    }
    
    public init?(parameters: Data) {
        guard parameters.isEmpty else {
            return nil
        }
    }
    
}
