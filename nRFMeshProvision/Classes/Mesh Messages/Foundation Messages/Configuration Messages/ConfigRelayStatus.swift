//
//  ConfigRelayStatus.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 05/08/2019.
//

import Foundation

public struct ConfigRelayStatus: ConfigMessage {
    public static let opCode: UInt32 = 0x8028
    
    public var parameters: Data? {
        return Data([state.rawValue]) + ((count & 0x07) | steps << 3)
    }
    
    /// The Relay state for the Node.
    public let state: NodeFeaturesState
    /// Number of retransmissions on advertising bearer for each Network PDU
    /// relayed by the Node. Possible values are 0...7, which correspond to
    /// 1-8 transmissions in total.
    public let count: UInt8
    /// Number of 10-millisecond steps between retransmissions, decremented by 1.
    /// Possible values are 0...31, which corresponds to 10-320 milliseconds
    /// intervals.
    public let steps: UInt8
    /// The interval between retransmissions, in seconds.
    public var interval: TimeInterval {
        return TimeInterval(steps + 1) / 100
    }
    
    /// Creates the Relay status message.
    ///
    /// - parameter state: The Relay status on the Node.
    /// - parameter count: Number of retransmissions on advertising bearer
    ///                    for each Network PDU relayed by the Node. Possible
    ///                    values are 0...7, which correspond to 1-8 transmissions
    ///                    in total.
    /// - parameter steps: Number of 10-millisecond steps between retransmissions,
    ///                    decremented by 1. Possible values are 0...31, which
    ///                    corresponds to 10-320 milliseconds intervals.
    public init(state: NodeFeaturesState, count: UInt8, steps: UInt8) {
        self.state = state
        self.count = min(7, count)
        self.steps = min(63, steps)
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 2 else {
            return nil
        }
        guard let state = NodeFeaturesState(rawValue: parameters[0]) else {
            return nil
        }
        self.state = state
        self.count = parameters[1] & 0x07
        self.steps = parameters[1] >> 3
    }
    
}

