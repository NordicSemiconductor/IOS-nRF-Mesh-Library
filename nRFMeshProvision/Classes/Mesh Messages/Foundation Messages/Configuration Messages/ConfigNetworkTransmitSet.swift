//
//  ConfigNetworkTransmitSet.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 05/08/2019.
//

import Foundation

public struct ConfigNetworkTransmitSet: AcknowledgedConfigMessage {
    public static let opCode: UInt32 = 0x8024
    public static let responseType: StaticMeshMessage.Type = ConfigNetworkTransmitStatus.self
    
    public var parameters: Data? {
        return Data() + ((count & 0x07) | steps << 3)
    }
    
    /// Number of message transmissions of Network PDU originating from the
    /// Node. Possible values are 0...7, which correspond to 1-8 transmissions
    /// in total.
    public let count: UInt8
    /// Number of 10-millisecond steps between transmissions, decremented by 1.
    /// Possible values are 0...31, which corresponds to 10-320 milliseconds
    /// intervals.
    public let steps: UInt8
    /// The interval between transmissions, in seconds.
    public var interval: TimeInterval {
        return TimeInterval(steps + 1) / 100
    }
    
    /// Sets the Network Transmit property of the Node.
    ///
    /// - parameter count: Number of message transmissions of Network PDU
    ///                    originating from the Node. Possible values are 0...7,
    ///                    which correspond to 1-8 transmissions in total.
    /// - parameter steps: Number of 10-millisecond steps between transmissions,
    ///                    decremented by 1. Possible values are 0...31, which
    ///                    corresponds to 10-320 milliseconds intervals.
    public init(count: UInt8, steps: UInt8) {
        self.count = min(7, count)
        self.steps = min(63, steps)
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 1 else {
            return nil
        }
        self.count = parameters[0] & 0x07
        self.steps = parameters[0] >> 3
    }
    
}

