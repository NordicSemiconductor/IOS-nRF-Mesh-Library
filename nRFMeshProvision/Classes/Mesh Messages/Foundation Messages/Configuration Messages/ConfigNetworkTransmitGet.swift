//
//  ConfigNetworkTransmitGet.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 05/08/2019.
//

import Foundation

public struct ConfigNetworkTransmitGet: AcknowledgedConfigMessage {
    public static let opCode: UInt32 = 0x8023
    public static let responseType: StaticMeshMessage.Type = ConfigNetworkTransmitStatus.self
    
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
