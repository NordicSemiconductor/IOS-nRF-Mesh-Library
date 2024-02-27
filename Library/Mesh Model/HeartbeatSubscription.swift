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

public class HeartbeatSubscription: Codable {
    
    internal class State {
        /// The timestamp at which the subscription was started.
        private let startDate: Date
        /// The Heartbeat Subscription Period state controls the duration for processing
        /// Heartbeat transport control messages. When set to 0x0000, Heartbeat messages
        /// are not processed. When set to a value greater than or equal to 0x0001,
        /// Heartbeat messages are processed.
        private let period: TimeInterval
        
        /// The Heartbeat Subscription Count state is a 16-bit counter that controls
        /// the number of periodical Heartbeat transport control messages received
        /// since receiving the most recent Config Heartbeat Subscription Set message.
        /// The counter stops counting at 0xFFFF.
        fileprivate(set) var count: UInt16 = 0
        /// The Heartbeat Subscription Min Hops state determines the minimum hops value
        /// registered when receiving Heartbeat messages since receiving the most recent
        /// Config Heartbeat Subscription Set message.
        fileprivate(set) var minHops: UInt8 = 0x7F
        /// The Heartbeat Subscription Max Hops state determines the maximum hops value
        /// registered when receiving Heartbeat messages since receiving the most recent
        /// Config Heartbeat Subscription Set message.
        fileprivate(set) var maxHops: UInt8 = 0
        
        /// The Heartbeat Subscription Period Log is a representation of the Heartbeat
        /// Subscription Period state value. The Heartbeat Subscription Period Log and
        /// Heartbeat Subscription Period with the value 0x00 and 0x0000 are equivalent.
        /// The Heartbeat Subscription Period Log value between 0x01 and 0x11 shall
        /// represent the Heartbeat Subscription Period value
        var periodLog: UInt8 {
            let timeIntervalSinceSubscriptionStarted = -startDate.timeIntervalSinceNow
            let remainingPeriod = period - timeIntervalSinceSubscriptionStarted
            guard remainingPeriod >= 0 else {
                return 0
            }
            return HeartbeatSubscription.period2PeriodLog(remainingPeriod)
        }
        /// The Heartbeat Subscription Count Log is a representation of the Heartbeat
        /// Subscription Count state value. The Heartbeat Subscription Count Log and
        /// Heartbeat Subscription Count with the value 0x00 and 0x0000 are equivalent.
        /// The Heartbeat Subscription Count Log value of 0xFF is equivalent to the Heartbeat
        /// Subscription count value of 0xFFFF. The Heartbeat Subscription Count Log value
        /// between 0x01 and 0x10 shall represent the Heartbeat Subscription Count value,
        /// using the transformation defined in Table 4.1, where 0xFF means that more than
        /// 0xFFFF messages were received.
        var countLog: UInt8 {
            return HeartbeatSubscription.countToCountLog(count)
        }
        
        fileprivate init(periodLog: UInt8) {
            self.startDate = Date()
            self.period = TimeInterval(HeartbeatSubscription.periodLog2Period(periodLog))
        }
    }
    /// The state contains variables used for handling Heartbeat messages received
    /// by the local Node.
    internal var state: State?
    
    /// The source address for the Heartbeat messages.
    ///
    /// It must be a Unicast Address.
    public let source: Address
    /// The destination address for the Heartbeat messages.
    ///
    /// It can be either a Group or Unicast Address.
    public let destination: Address
    
    /// Returns whether the subscription is enabled, or not.
    ///
    /// Subscription gets disabled when the specified period times out.
    internal var isEnabled: Bool {
        return state.map { $0.periodLog > 0 } ?? false
    }
    
    /// Returns whether the received Heartbeat message matches subscription parameters.
    ///
    /// - parameter heartbeat: The received Heartbeat message.
    /// - returns: True, if Heartbeat message matches the subscription; false otherwise.
    internal func matches(_ heartbeat: HeartbeatMessage) -> Bool {
        return source == heartbeat.source && destination == heartbeat.destination
    }
    
    /// Updates the counter based on received Heartbeat message.
    ///
    /// - parameter heartbeat: The received Heartbeat message.
    internal func updateIfMatches(_ heartbeat: HeartbeatMessage) {
        guard isEnabled, let state = state, matches(heartbeat) else {
            return
        }
        if state.count < 0xFFFF {
            state.count += 1
        }
        state.minHops = min(state.minHops, heartbeat.hops)
        state.maxHops = max(state.maxHops, heartbeat.hops)
    }
    
    /// An initializer for remote Nodes' Heartbeat subscription objects.
    ///
    /// - parameter status: The received status containing current Heartbeat
    ///                     subscription information.
    /// - returns: The Heartbeat subscription object, or `nil`, it the message
    ///            defines it as disabled. 
    internal init?(_ status: ConfigHeartbeatSubscriptionStatus) {
        guard status.isEnabled else {
            return nil
        }
        self.source = status.source
        self.destination = status.destination
        // The current state of the heartbeat subscription is not set for 2 reasons:
        // - it is dynamic - the device is listening for heartbeat messages for some time only,
        // - it is not saved in the Configuration Database.
        //
        // self.state = State(periodLog: status.periodLog)
    }
    
    /// An initializer for local Node. This sets the state to the value from the
    /// Config Heartbeat Subscription Set message.
    ///
    /// - parameter request: The request sent to the local Node.
    /// - returns: The Heartbeat subscription object, or `nil`, it the message
    ///            disables it.
    internal init?(_ request: ConfigHeartbeatSubscriptionSet) {
        guard request.enablesSubscription else {
            return nil
        }
        self.source = request.source
        self.destination = request.destination
        // Here, the state is stored for purpose of subscription.
        // This method is called only for the local Node.
        // The value is not persistent and subscription will stop when the app
        // gets restarted.
        self.state = State(periodLog: request.periodLog)
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case source
        case destination
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let sourceAsString = try container.decode(String.self, forKey: .source)
        guard let source = Address(hex: sourceAsString) else {
            throw DecodingError.dataCorruptedError(forKey: .source, in: container,
                                                   debugDescription: "Source address must be 4-character hexadecimal string.")
        }
        guard source.isUnicast else {
            throw DecodingError.dataCorruptedError(forKey: .source, in: container,
                                                   debugDescription: "\(sourceAsString) is not a unicast address.")
        }
        self.source = source
        let destinationAsString = try container.decode(String.self, forKey: .destination)
        guard let destination = Address(hex: destinationAsString) else {
            throw DecodingError.dataCorruptedError(forKey: .destination, in: container,
                                                   debugDescription: "Destination address must be 4-character hexadecimal string.")
        }
        guard destination.isUnicast || destination.isGroup else {
            throw DecodingError.dataCorruptedError(forKey: .destination, in: container,
                                                   debugDescription: "\(destinationAsString) is not a unicast or group address.")
        }
        self.destination = destination
        self.state = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(source.hex, forKey: .source)
        try container.encode(destination.hex, forKey: .destination)
    }
}

private extension HeartbeatSubscription {
    
    /// Converts Subscription Count to Subscription Count Log.
    ///
    /// This method uses algorithm compatible to Table 4.1 in Bluetooth Mesh Profile
    /// Specification 1.0.1.
    ///
    /// - parameter value: The count.
    /// - returns: The logarithmic value.
    static func countToCountLog(_ value: UInt16) -> UInt8 {
        switch value {
        case 0x0000:
            // No Heartbeat messages were received.
            return 0x00
        case 0xFFFF:
            // Maximum value.
            return 0xFF
        default:
            return UInt8(log2(Double(value)) + 1)
        }
    }
    
    /// Converts Subscription Period to Subscription Period Log.
    ///
    /// - parameter remainingPeriod: The remaining period, as `TimeInterval`.
    /// - returns: The logarithmic value.
    static func period2PeriodLog(_ remainingPeriod: TimeInterval) -> UInt8 {
        switch remainingPeriod {
        case 0:
            // Periodic Heartbeat messages are not published.
            return 0x00
        case let max where max >= 0xFFFF:
            // Maximum value.
            return 0x11
        default:
            return UInt8(log2(remainingPeriod) + 1)
        }
    }
    
    /// Converts Subscription Period Log to Subscription Period.
    ///
    /// - parameter periodLog: The logarithmic value in range 0x00...0x11.
    /// - returns: The value.
    static func periodLog2Period(_ periodLog: UInt8) -> UInt16 {
        switch periodLog {
        case 0x00:
            // Periodic Heartbeat messages are not published.
            return 0x0000
        case let exponent where exponent >= 0x01 && exponent <= 0x10:
            // Period = 2^(n-1) seconds.
            return UInt16(pow(2.0, Double(exponent - 1)))
        case 0x11:
            // Maximum value.
            return 0xFFFF
        default:
            fatalError("PeriodLog out or range: \(periodLog) (required: 0x00-0x11)")
        }
    }
    
}

