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

public struct ConfigHeartbeatPublicationStatus: ConfigMessage, ConfigStatusMessage, ConfigNetKeyMessage {
    public static let opCode: UInt32 = 0x06
    
    public var parameters: Data? {
        var data = Data([status.rawValue]) + destination
        data += countLog
        data += periodLog
        data += ttl
        data += featuresBits
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
    /// - 0xFF - Periodic Heartbeat messages are publishedbeing sent indefinitely.
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
    internal let countLog: UInt8
    /// Period for sending Heartbeat messages.
    ///
    /// Possible values:
    /// - 0x00 - Periodic Heartbeat messages are not published.
    /// - 0x01 - 0x11 - Publication period represented as 2^(n-1) seconds.
    /// - Other values are prohibited.
    ///
    /// The value is represented as 2^(n-1) seconds. For example, the value 0x04 would
    /// have a publication period of 8 seconds, and the value 0x07 would have a publication
    /// period of 64 seconds.
    internal let periodLog: UInt8
    /// TTL to be used when sending Heartbeat messages.
    ///
    /// Valid values are in range 0-127.
    public let ttl: UInt8
    /// Bit field indicating features that trigger Heartbeat messages when changed.
    internal let featuresBits: UInt16
    /// The Heartbeat Publication Features state determines the features that trigger
    /// sending Heartbeat messages when changed.
    public var features: NodeFeaturesState {
        return NodeFeaturesState(rawValue: featuresBits)
    }
    
    /// Returns whether Heartbeat publishing is enabled.
    public var isEnabled: Bool {
        return destination != .unassignedAddress
    }
    
    /// Returns whether periodic Heartbeat publishing is enabled.
    public var isPeriodicPublicationEnabled: Bool {
        return isEnabled && periodLog > 0
    }
    
    /// Returns whether feature-trigerred Heartbeat publishing is enabled.
    public var isFeatureTrigerredPublishingEnabled: Bool {
        return isEnabled && featuresBits != 0
    }
    
    public init(responseTo request: ConfigHeartbeatPublicationGet, with publication: HeartbeatPublication?) {
        self.destination = publication?.address ?? .unassignedAddress
        self.countLog = publication?.state?.countLog ?? 0
        self.periodLog = publication?.periodLog ?? 0
        self.ttl = publication?.ttl ?? 0
        self.featuresBits = publication?.features.toSet().rawValue ?? 0
        self.networkKeyIndex = publication?.networkKeyIndex ?? 0
        self.status = .success
    }
    
    public init(responseTo request: ConfigHeartbeatPublicationSet, with status: ConfigMessageStatus) {
        self.destination = request.destination
        self.countLog = request.countLog
        self.periodLog = request.periodLog
        self.ttl = request.ttl
        self.featuresBits = request.featuresBits
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
        self.featuresBits = parameters.read(fromOffset: 6)
        self.networkKeyIndex = parameters.read(fromOffset: 8)
    }
    
}

