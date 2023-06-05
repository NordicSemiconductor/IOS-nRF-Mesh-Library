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

public class HeartbeatPublication: Codable {
    
    internal class PeriodicHeartbeatState {
        /// The current publication count.
        ///
        /// This is set by the Config Heartbeat Publication Set message and decremented
        /// each time a Heartbeat message is sent, until it reaches 0, which means that
        /// periodic Heartbeat messages are disabled.
        ///
        /// Possible values are:
        /// - 0x0000 - Periodic Heartbeats are disabled.
        /// - 0x0001 - 0xFFFE - Number of remaining Heartbeat messages to be sent.
        /// - 0xFFFF - Periodic Heartbeat messages are published indefinitely.
        private var count: UInt16
        
        /// Number of Heartbeat messages remaining to be sent, represented as 2^(n-1) seconds.
        var countLog: UInt8 {
            return HeartbeatPublication.countToCountLog(count)
        }
        
        fileprivate init?(_ countLog: UInt8) {
            switch countLog {
            case 0x00:
                // Periodic Heartbeat messages are not published.
                return nil
            case let exponent where exponent >= 1 && exponent <= 0x10:
                count = UInt16(pow(2.0, Double(exponent - 1)))
            case 0x11:
                // Maximum possible value.
                count = 0xFFFE
            case 0xFF:
                // Periodic Heartbeat messages are published indefinitely.
                count = 0xFFFF
            default:
                // Invalid value.
                return nil
            }
        }
        
        /// Returns whether more periodic Heartbeat message should be sent, or not.
        /// - returns: True, if more Heartbeat control message should be sent;
        ///            false otherwise.
        func shouldSendMorePeriodicHeartbeatMessage() -> Bool {
            guard count > 0 else {
                return false
            }
            guard count < 0xFFFF else {
                return true
            }
            count = count - 1
            return true
        }
    }
    /// The periodic heartbeat state contains variables used for handling sending
    /// periodic Heartbeat messages from the local Node.
    internal var state: PeriodicHeartbeatState?
    
    /// The destination address for the Heartbeat messages.
    /// 
    /// It can be either a Group or Unicast Address.
    public let address: Address
    /// The Heartbeat Publication Period Log state is an 8-bit value that controls
    /// the period between the publication of two consecutive periodical Heartbeat
    /// transport control messages. The value is represented as 2^(n-1) seconds.
    ///
    /// Period Log equal to 0 means periodic Heartbeat publications are disabled.
    /// Value 0xFF means 0xFFFF seconds.
    public let periodLog: UInt8
    /// The cadence of periodical Heartbeat messages in seconds.
    public var period: UInt16 {
        return Self.periodLog2Period(periodLog)
    }
    /// The TTL (Time to Live) value for the Heartbeat messages.
    public let ttl: UInt8
    /// The index property contains an integer that represents a Network Key Index,
    /// indicating which network key to use for the Heartbeat publication.
    ///
    /// The Network Key Index corresponds to the index value of one of the Network Key
    /// entries in Node ``Node/networkKeys`` array.
    public let networkKeyIndex: KeyIndex
    /// Node features that trigger sending Heartbeat messages when changed.
    public let features: NodeFeatures
    
    /// Returns whether Heartbeat publishing shall be enabled.
    public var isEnabled: Bool {
        return address != .unassignedAddress
    }
    
    /// Returns whether periodic Heartbeat publishing shall be enabled.
    public var isPeriodicPublicationEnabled: Bool {
        return isEnabled && periodLog > 0
    }
    
    /// Returns whether feature-triggered Heartbeat publishing shall be enabled.
    public var isFeatureTriggeredPublishingEnabled: Bool {
        return isEnabled && !features.isEmpty
    }
    
    /// An initializer for remote Nodes' Heartbeat publication objects.
    ///
    /// - parameter status: The received status containing current Heartbeat publication
    ///                     information.
    internal init?(_ status: ConfigHeartbeatPublicationStatus) {
        guard status.isEnabled else {
            return nil
        }
        self.address = status.destination
        self.periodLog = status.periodLog
        self.ttl = status.ttl
        self.networkKeyIndex = status.networkKeyIndex
        self.features = status.features
        // The current state of the heartbeat publication is not set for 2 reasons:
        // - it is dynamic - the device is sending heartbeat messages and the count goes down
        // - it is not saved in the Configuration Database.
        //
        // self.state = PeriodicHeartbeatState(status.countLog)
    }
    
    /// An initializer for local Node. This sets the count to the value from the Set
    /// message.
    ///
    /// - parameter request: The request sent to the local Node.
    internal init?(_ request: ConfigHeartbeatPublicationSet) {
        guard request.enablesPublication else {
            return nil
        }
        self.address = request.destination
        self.periodLog = request.periodLog
        self.ttl = request.ttl
        self.networkKeyIndex = request.networkKeyIndex
        self.features = request.features
        // Here, the state is stored for purpose of publication.
        // This method is called only for the local Node.
        // The value is not persistent and publications will stop when the app
        // gets restarted.
        self.state = PeriodicHeartbeatState(request.countLog)
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case address
        case period
        case ttl
        case networkKeyIndex = "index"
        case features
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let addressAsString = try container.decode(String.self, forKey: .address)
        guard let address = Address(hex: addressAsString) else {
            throw DecodingError.dataCorruptedError(forKey: .address, in: container,
                                                   debugDescription: "Address must be 4-character hexadecimal string.")
        }
        guard address.isUnicast || address.isGroup else {
            throw DecodingError.dataCorruptedError(forKey: .address, in: container,
                                                   debugDescription: "\(addressAsString) is not a unicast or group address.")
        }
        self.address = address
        let period = try container.decode(UInt16.self, forKey: .period)
        guard let periodLog = Self.period2PeriodLog(period) else {
            throw DecodingError.dataCorruptedError(forKey: .period, in: container,
                                                   debugDescription: "Period must be power of 2 or 0xFFFF.")
        }
        self.periodLog = periodLog
        let ttl = try container.decode(UInt8.self, forKey: .ttl)
        guard ttl <= 127 else {
            throw DecodingError.dataCorruptedError(forKey: .ttl, in: container,
                                                   debugDescription: "TTL must be in range 0-127.")
        }
        self.ttl = ttl
        self.networkKeyIndex = try container.decode(KeyIndex.self, forKey: .networkKeyIndex)
        let features = try container.decode([NodeFeature].self, forKey: .features)
        self.features = features.asSet()
        
        // On reset or import periodic Heartbeat messages are stopped.
        self.state = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(address.hex, forKey: .address)
        try container.encode(period, forKey: .period)
        try container.encode(ttl, forKey: .ttl)
        try container.encode(networkKeyIndex, forKey: .networkKeyIndex)
        try container.encode(features.asArray(), forKey: .features)
    }
}

private extension HeartbeatPublication {
    
    /// Converts Publication Count to Publication Count Log.
    ///
    /// - parameter count: The count.
    /// - returns: The logarithmic value.
    static func countToCountLog(_ count: UInt16) -> UInt8 {
        switch count {
        case 0x00:
            // Periodic Heartbeats are disabled.
            return 0x00
        case 0xFFFF:
            // Periodic Heartbeat messages are published indefinitely.
            return 0xFF
        default:
            // The Heartbeat Publication Count Log value between 0x01 and 0x11 shall
            // represent that smallest integer n where 2^(n-1) is greater than or equal
            // to the Heartbeat Publication Count value.
            //
            // For example, if the Heartbeat Publication Count value is 0x0579, then
            // the Heartbeat Publication Count Log value would be 0x0C.
            //
            // Value  Log
            // 1      1  because 2^(1-1) = 1, which is >= 1
            // 2      2  because 2^(2-1) = 2, which is >= 2
            // 3      3  because 2^(3-1) = 4, which is >= 3 and 2^(2-1) = 2 is < 3
            // 4      3  because 2^(3-1) = 4, which is >= 4
            // 5      4  because 2^(4-1) = 8, which is >= 5 and 2^(3-1) = 4 is < 5
            // 0x0579 12 because 2^(12-1) = 204, which is >= 1401, and 2^(11-1) = 1024 is < 1401*
            // * 0x0579 = 1401
            return UInt8(log2(Double(count) * 2 - 1)) + 1
        }
    }
    
    /// Converts Publication Period to Publication Period Log.
    ///
    /// - parameter value: The value.
    /// - returns: The logarithmic value.
    static func period2PeriodLog(_ value: UInt16) -> UInt8? {
        switch value {
        case 0x0000:
            // Periodic Heartbeat messages are not published.
            return 0x00
        case 0xFFFF:
            // Maximum value.
            return 0x11
        default:
            let exponent = UInt8(log2(Double(value) * 2 - 1)) + 1
            guard pow(2.0, Double(exponent - 1)) == Double(value) else {
                // Ensure power of 2.
                return nil
            }
            return exponent
        }
    }
    
    /// Converts Publication Period Log to Publication Period.
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
