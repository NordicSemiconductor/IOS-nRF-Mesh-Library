//
//  ConfigBeaconStatus.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 09/08/2019.
//

import Foundation

public struct ConfigBeaconStatus: ConfigMessage {
    public static let opCode: UInt32 = 0x800B
    
    public var parameters: Data? {
        return Data([isEnabled ? 0x01 : 0x00])
    }
    
    /// Secure Network Beacon state.
    public let isEnabled: Bool
    
    /// Configures the Secure Network Beacon behavior on the Node.
    ///
    /// - parameter enabled: `True` to enable Secure Network Beacon feature,
    ///                      `false` to disable.
    public init(enabled: Bool) {
        self.isEnabled = enabled
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 1 else {
            return nil
        }
        guard parameters[0] <= 1 else {
            return nil
        }
        self.isEnabled = parameters[0] == 0x01
    }
    
}
