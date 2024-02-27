/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

public struct ConfigHeartbeatSubscriptionStatus: ConfigResponse, ConfigStatusMessage {
    public static let opCode: UInt32 = 0x803C
    
    public var parameters: Data? {
        var data = Data([status.rawValue]) + source + destination
        data += periodLog
        data += countLog
        data += minHops
        data += maxHops
        return data
    }
    
    public let status: ConfigMessageStatus
    
    /// Source address for Heartbeat messages.
    ///
    /// The Heartbeat Subscription Source shall be the Unassigned Address or a Unicast a
    /// Address, all other values are Prohibited.
    ///
    /// If the Heartbeat Subscription Source is set to the Unassigned Address,
    /// the Heartbeat messages are not processed and subscription will be cancelled.
    public let source: Address
    /// Destination address for Heartbeat messages.
    ///
    /// The Heartbeat Subscription Destination shall be the Unassigned Address, a Unicast
    /// Address, or a Group Address, all other values are Prohibited.
    ///
    /// If the Heartbeat Subscription Destination is set to the Unassigned Address, the
    /// Heartbeat messages are not processed.
    public let destination: Address
    /// Remaining Period for processing Heartbeat messages.
    ///
    /// Possible values (See table 4.1 in Bluetooth Mesh Specification 1.0.1):
    /// - 0x00 - Periodic Heartbeat messages are not processed.
    /// - 0x01 - 0x10 - Remaining period, in 2^(n-1) seconds, for processing Heartbeat messages.
    /// - 0x11 - Remaining period of 65535 (0xFFFF) seconds. 
    /// - Other values are Prohibited.
    public let periodLog: UInt8
    /// Remaining Period for processing Heartbeat messages.
    ///
    /// Value 0 means that periodic Heartbeat messages will not be processed.
    public var period: RemainingHeartbeatSubscriptionPeriod {
        switch periodLog {
        case 0x00:
            return .disabled
        case 0x01:
            return .exact(1)
        case 0x11:
            return .exact(0xFFFF)
        case let valid where valid >= 0x02 && valid < 0x11:
            let lowerBound = UInt16(pow(2.0, Double(periodLog) - 1))
            let upperBound = UInt16(pow(2.0, Double(periodLog)) - 1)
            return .range(lowerBound...upperBound)
        default:
            return .invalid(periodLog: periodLog)
        }
    }
    /// Number of Heartbeat messages received.
    ///
    /// Possible values (See table 4.1 in Bluetooth Mesh Specification 1.0.1):
    /// - 0x00 - 0x10 - Number of Heartbeat messages, 2^(n-1), that were received.
    /// - 0xFF - More than 0xFFFE Heartbeat messages were received.
    /// - Other values are Prohibited.
    ///
    /// The Heartbeat Subscription Count Log is a representation of the Heartbeat Subscription
    /// Count state value. The Heartbeat Subscription Count Log and Heartbeat Subscription Count
    /// with the value 0x00 and 0x0000 are equivalent. The Heartbeat Subscription Count Log
    /// value of 0xFF is equivalent to the Heartbeat Subscription count value of 0xFFFF.
    /// The Heartbeat Subscription Count Log value between 0x01 and 0x10 shall represent the
    /// Heartbeat Subscription Count value.
    public let countLog: UInt8
    /// Number of Heartbeat messages received.
    public var count: HeartbeatSubscriptionCount {
        switch countLog {
        case 0x00, 0x01:
            return .exact(UInt16(countLog))
        case 0xFF, 0x11:
            return .reallyALot
        case let valid where valid >= 0x02 && valid <= 0x10:
            let lowerBound = UInt16(pow(2.0, Double(countLog) - 1))
            let upperBound = min(0xFFFE, UInt16(pow(2.0, Double(countLog)) - 1))
            return .range(lowerBound...upperBound)
        default:
            return .invalid(countLog: countLog)
        }
    }
    /// The Heartbeat Subscription Min Hops state determines the minimum hops value registered
    /// when receiving Heartbeat messages since receiving the most recent Config Heartbeat
    /// Subscription Set message or reset.
    public let minHops: UInt8
    /// The Heartbeat Subscription Max Hops state determines the maximum hops value registered
    /// when receiving Heartbeat messages since receiving the most recent Config Heartbeat
    /// Subscription Set message or reset
    public let maxHops: UInt8
    
    /// Returns whether processing of Heartbeat messages is enabled.
    public var isEnabled: Bool {
        return source != .unassignedAddress && destination != .unassignedAddress
    }
    /// Returns whether processing of Heartbeat messages has finished.
    public var isComplete: Bool {
        return source != .unassignedAddress && destination != .unassignedAddress && periodLog == 0
    }
    
    public init(_ subscription: HeartbeatSubscription?) {
        self.source = subscription?.source ?? .unassignedAddress
        self.destination = subscription?.destination ?? .unassignedAddress
        self.periodLog = subscription?.state?.periodLog ?? 0
        self.countLog = subscription?.state?.countLog ?? 0
        self.minHops = subscription?.state?.minHops ?? 0
        self.maxHops = subscription?.state?.maxHops ?? 0
        self.status = .success
    }
    
    public init(cancel subscription: HeartbeatSubscription) {
        self.source = .unassignedAddress
        self.destination = .unassignedAddress
        self.periodLog = subscription.state?.periodLog ?? 0
        self.countLog = subscription.state?.countLog ?? 0
        self.minHops = subscription.state?.minHops ?? 0
        self.maxHops = subscription.state?.maxHops ?? 0
        self.status = .success
    }
    
    public init(responseTo request: ConfigHeartbeatSubscriptionSet, with status: ConfigMessageStatus) {
        self.source = request.source
        self.destination = request.destination
        self.periodLog = request.periodLog
        self.countLog = 0
        self.minHops = 0x7F
        self.maxHops = 0x00
        self.status = status
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 9 else {
            return nil
        }
        guard let status = ConfigMessageStatus(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        self.source = parameters.read(fromOffset: 1)
        self.destination = parameters.read(fromOffset: 3)
        self.periodLog = parameters.read(fromOffset: 5)
        self.countLog = parameters.read(fromOffset: 6)
        self.minHops = parameters.read(fromOffset: 7)
        self.maxHops = parameters.read(fromOffset: 8)
    }
    
}

