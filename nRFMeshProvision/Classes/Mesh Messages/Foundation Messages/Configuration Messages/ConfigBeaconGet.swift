//
//  ConfigBeaconGet.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 09/08/2019.
//

import Foundation

public struct ConfigBeaconGet: AcknowledgedConfigMessage {
    public static let opCode: UInt32 = 0x8009
    public static let responseType: StaticMeshMessage.Type = ConfigBeaconStatus.self
    
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
