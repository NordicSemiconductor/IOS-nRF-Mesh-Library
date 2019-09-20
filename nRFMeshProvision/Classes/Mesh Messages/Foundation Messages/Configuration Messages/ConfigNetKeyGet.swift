//
//  ConfigNetKeyGet.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 27/06/2019.
//

import Foundation

public struct ConfigNetKeyGet: AcknowledgedConfigMessage {
    public static let opCode: UInt32 = 0x8042
    public static let responseType: StaticMeshMessage.Type = ConfigNetKeyList.self
    
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
