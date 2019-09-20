//
//  ConfigGATTProxySet.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 06/08/2019.
//

import Foundation

public struct ConfigGATTProxySet: AcknowledgedConfigMessage {
    public static let opCode: UInt32 = 0x8013
    public static let responseType: StaticMeshMessage.Type = ConfigGATTProxyStatus.self
    
    public var parameters: Data? {
        return Data([state.rawValue])
    }
    
    /// The new GATT Proxy state of the Node.
    public let state: NodeFeaturesState
    
    /// Configures the GATT Proxy on the Node.
    ///
    /// When disabled, the Node will no longer be able to work as a GATT Proxy
    /// until enabled again.
    ///
    /// - parameter enable: `True` to enable GATT Proxy feature, `false` to disable.
    public init(enable: Bool) {
        self.state = enable ? .enabled : .notEnabled
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 1 else {
            return nil
        }
        guard let state = NodeFeaturesState(rawValue: parameters[0]) else {
            return nil
        }
        self.state = state
    }
    
}
