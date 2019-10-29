//
//  ConfigBeaconSet.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 09/08/2019.
//

import Foundation

public struct ConfigBeaconSet: AcknowledgedConfigMessage {
    public static let opCode: UInt32 = 0x800A
    public static let responseType: StaticMeshMessage.Type = ConfigBeaconStatus.self
    
    public var parameters: Data? {
        return Data([state ? 0x01 : 0x00])
    }
    
    /// New Secure Network Beacon state.
    public let state: Bool
    
    /// Configures the Secure Network Beacon behavior on the Node.
    ///
    /// - parameter enable: `True` to enable Secure Network Beacon feature,
    ///                     `false` to disable.
    public init(enable: Bool) {
        self.state = enable
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 1 else {
            return nil
        }
        guard parameters[0] <= 1 else {
            return nil
        }
        self.state = parameters[0] == 0x01
    }
    
}
