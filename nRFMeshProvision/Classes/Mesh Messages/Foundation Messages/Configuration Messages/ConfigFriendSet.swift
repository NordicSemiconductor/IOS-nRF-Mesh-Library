//
//  ConfigFriendSet.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 06/08/2019.
//

import Foundation

public struct ConfigFriendSet: AcknowledgedConfigMessage {
    public static let opCode: UInt32 = 0x8010
    public static let responseType: StaticMeshMessage.Type = ConfigFriendStatus.self
    
    public var parameters: Data? {
        return Data([state.rawValue])
    }
    
    /// The new Friend state of the Node.
    public let state: NodeFeaturesState
    
    /// Configures the Friend feature on the Node.
    ///
    /// - parameter enable: `True` to enable Friend feature, `false` to disable.
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
