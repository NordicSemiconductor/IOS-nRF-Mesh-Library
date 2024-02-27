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

public struct ConfigHeartbeatPublicationStatus: ConfigResponse, ConfigStatusMessage, ConfigNetKeyMessage {
    public static let opCode: UInt32 = 0x06
    
    public var parameters: Data? {
        var data = Data([status.rawValue]) + destination
        data += countLog
        data += periodLog
        data += ttl
        data += features.rawValue
        data += networkKeyIndex
        return data
    }
    
    public let status: ConfigMessageStatus
    public let networkKeyIndex: KeyIndex

    /// Destination address for Heartbeat messages.
    ///
    /// The Heartbeat Publication Destination shall be the Unassigned Address, a Unicast
    /// Address, or a Group Address, all other values are Prohibited.
    ///
    /// If the Heartbeat Publication Destination is set to the Unassigned Address, the
    /// Heartbeat messages are not being sent.
    public let destination: Address
    /// Number of Heartbeat messages remaining to be sent.
    ///
    /// Possible values:
    /// - 0x00 - Periodic Heartbeat messages are not published.
    /// - 0x01 - 0x11 - Number of Heartbeat messages, 2^(n-1), that remain to be sent.
    /// - 0xFF - Periodic Heartbeat messages are published sent indefinitely.
    /// - Other values are prohibited.
    ///
    /// The Heartbeat Publication Count Log is a representation of the Heartbeat Publication
    /// Count state value. The Heartbeat Publication Count Log and Heartbeat Publication Count
    /// with the value 0x00 and 0x0000 are equivalent. The Heartbeat Publication Count Log
    /// value of 0xFF is equivalent to the Heartbeat Publication count value of 0xFFFF.
    /// The Heartbeat Publication Count Log value between 0x01 and 0x11 shall represent that
    /// smallest integer n where 2^(n-1) is greater than or equal to the Heartbeat Publication
    /// Count value. For example, if the Heartbeat Publication Count value is 0x0579, then the
    /// Heartbeat Publication Count Log value would be 0x0C.
    public let countLog: UInt8
    /// Number of Heartbeat messages remaining to be sent.
    public var count: RemainingHeartbeatPublicationCount {
        switch countLog {
        case 0x00:
            return .disabled
        case 0xFF:
            return .indefinitely
        case 0x01, 0x02:
            return .exact(UInt16(countLog))
        case 0x11:
            return .range(0x8001...0xFFFE)
        case let valid where valid >= 0x03 && valid <= 0x10:
            let lowerBound = UInt16(pow(2.0, Double(countLog - 2))) + 1
            let upperBound = UInt16(pow(2.0, Double(countLog - 1)))
            return .range(lowerBound...upperBound)
        default:
            return .invalid(countLog: countLog)
        }
    }
    /// Period between the publication of two consecutive periodical Heartbeat transport
    /// control messages.
    ///
    /// Possible values:
    /// - 0x00 - Periodic Heartbeat messages are not published.
    /// - 0x01 - 0x10 - Publication period represented as 2^(n-1) seconds.
    /// - 0x11 - Period of 65535 (0xFFFF) seconds.
    /// - Other values are prohibited.
    ///
    /// The value is represented as 2^(n-1) seconds. For example, the value 0x04 would
    /// have a publication period of 8 seconds, and the value 0x07 would have a publication
    /// period of 64 seconds.
    public let periodLog: UInt8
    /// Period between the publication of two consecutive periodical Heartbeat transport
    /// control messages, in seconds.
    ///
    /// Value 0 means that periodic Heartbeat messages are not published.
    public var period: UInt16 {
        if periodLog == 0 {
            return 0x0000 // Periodic Heartbeat messages are not published.
        }
        guard periodLog < 0x11 else {
            return 0xFFFF // Maximum period.
        }
        return UInt16(pow(2.0, Double(periodLog - 1)))
    }
    /// TTL to be used when sending Heartbeat messages.
    ///
    /// Valid values are in range 0-127.
    public let ttl: UInt8
    /// The Heartbeat Publication Features state determines the features that trigger
    /// sending Heartbeat messages when changed.
    ///
    /// - If the Relay feature is set, a triggered Heartbeat message shall be published when
    ///   the Relay state of a Node changes.
    /// - If the Proxy feature is set, a triggered Heartbeat message shall be published when
    ///   the GATT Proxy state of a Node changes.
    /// - If the Friend feature is set, a triggered Heartbeat message shall be published when
    ///   the Friend state of a Node changes.
    /// - If the Low Power feature is set, a triggered Heartbeat message shall be published when
    ///   the Node establishes or loses Friendship.
    public let features: NodeFeatures
    
    /// Returns whether Heartbeat publishing is enabled.
    public var isEnabled: Bool {
        return destination != .unassignedAddress
    }
    
    /// Returns whether periodic Heartbeat publishing is enabled.
    public var isPeriodicPublicationEnabled: Bool {
        return isEnabled && periodLog > 0
    }
    
    /// Returns whether feature-triggered Heartbeat publishing is enabled.
    public var isFeatureTriggeredPublishingEnabled: Bool {
        return isEnabled && !features.isEmpty
    }
    
    public init(_ publication: HeartbeatPublication?) {
        self.destination = publication?.address ?? .unassignedAddress
        self.countLog = publication?.state?.countLog ?? 0
        self.periodLog = publication?.periodLog ?? 0
        self.ttl = publication?.ttl ?? 0
        self.features = publication?.features ?? []
        self.networkKeyIndex = publication?.networkKeyIndex ?? 0
        self.status = .success
    }
    
    public init(responseTo request: ConfigHeartbeatPublicationSet, with status: ConfigMessageStatus) {
        self.destination = request.destination
        self.countLog = request.countLog
        self.periodLog = request.periodLog
        self.ttl = request.ttl
        self.features = request.features
        self.networkKeyIndex = request.networkKeyIndex
        self.status = status
    }
    
    public init(confirm request: ConfigHeartbeatPublicationSet) {
        self.init(responseTo: request, with: .success)
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 10 else {
            return nil
        }
        guard let status = ConfigMessageStatus(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        self.destination = parameters.read(fromOffset: 1)
        self.countLog = parameters.read(fromOffset: 3)
        self.periodLog = parameters.read(fromOffset: 4)
        self.ttl = parameters.read(fromOffset: 5)
        self.features = NodeFeatures(rawValue: parameters.read(fromOffset: 6))
        self.networkKeyIndex = parameters.read(fromOffset: 8)
    }
    
}
