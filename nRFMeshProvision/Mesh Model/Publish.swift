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

/// The Publish object defines the publication configuration for a Model.
///
/// When a Model is configured for publishing, it will sent messages whenever a state
/// of the Model has changed, or periodically. The Publish object defines the destination
/// address and the Application Key to encrypt the messages, together with other settings.
///
/// To set the publication on a Model, send the ``ConfigModelPublicationSet`` or
/// ``ConfigModelPublicationVirtualAddressSet`` messages to the Configuration Server model
/// on the Node. The *Set* messages are confirmed with a ``ConfigModelPublicationStatus``.
public struct Publish: Codable, Equatable {
    /// The configuration for disabling publication.
    ///
    /// - since: 3.0
    public static let disabled = Publish()
    
    /// The object is used to describe the number of times a message is published and
    /// the interval between retransmissions of the published message.
    public struct Retransmit: Codable, Equatable {
        /// Retransmission of published messages is disabled.
        ///
        /// - since: 3.0
        public static let disabled = Retransmit()
        
        /// Number of retransmissions for network messages.
        /// The value is in range from 0 to 7, where 0 means no retransmissions.
        public let count: UInt8
        /// The interval (in milliseconds) between retransmissions (50...1600 with step 50).
        public let interval: UInt16
        /// Retransmission steps, from 0 to 31. Use ``Publish/Retransmit-swift.struct/interval``
        /// to get the interval in ms.
        public var steps: UInt8 {
            return UInt8((interval / 50) - 1)
        }
        
        /// Creates the Retransmit object when there should be no retransmissions.
        ///
        /// - seeAlso: ``Publish/Retransmit/disabled``.
        /// - since: 3.0
        public init() {
            count = 0
            interval = 50
        }
        
        /// Creates the Retransmit object.
        ///
        /// - parameters:
        ///   - count: Number of retransmissions for network messages. The value is in
        ///            range from 0 to 7, where 0 means no retransmissions.
        ///   - interval: The interval (in seconds) between retransmissions, from 0.050
        ///               second to 1.6 second with 50 milliseconds (0.050 second) step.
        /// - since: 3.0
        public init(_ count: UInt8, timesWithInterval interval: TimeInterval) {
            self.count = min(count, 7)
            // Interval is in 50 ms steps.
            self.interval = max(50, min(1600, UInt16(interval / 0.050) * 50))
        }
        
        /// Creates the Retransmit object.
        ///
        /// - parameters:
        ///   - publishRetransmitCount: Publish Retransmit Count value, in range 0...7.
        ///   - intervalSteps: Retransmission steps, from 0 to 31. Each step adds 50 ms
        ///                    to initial 50 ms interval.
        public init(publishRetransmitCount: UInt8, intervalSteps: UInt8) {
            count    = min(publishRetransmitCount, 7)
            // Interval is in 50 ms steps.
            interval = UInt16(intervalSteps + 1) * 50 // ms
        }
    }
    
    /// The Publish Period state determines the interval at which status messages
    /// are periodically published by a Model.
    ///
    /// - since: 3.0
    public struct Period: Codable, Equatable {
        /// Periodic publishing of status messages is disabled.
        ///
        /// - since: 3.0
        public static let disabled = Period()
        
        /// The number of steps, in range 0...63.
        public let numberOfSteps: UInt8
        /// The resolution of the number of steps.
        public let resolution: StepResolution
        /// The interval between subsequent publications in seconds.
        public let interval: TimeInterval
        
        /// Creates the Period object when periodic publication is disabled.
        ///
        /// - seeAlso: ``Publish/Period-swift.struct/disabled``.
        /// - since: 3.0
        public init() {
            self.numberOfSteps = 0
            self.resolution = .hundredsOfMilliseconds
            self.interval = 0.0
        }
        
        /// Creates the Period object.
        ///
        /// The given value will be translated to steps and resolution according to
        /// Bluetooth Mesh Profile 1.0.1 specification, chapter 4.2.2.2.
        ///
        /// - parameter interval: The periodic publishing interval, in seconds.
        /// - since: 3.0
        public init(_ interval: TimeInterval) {
            switch interval {
            case let interval where interval <= 0:
                numberOfSteps = 0
                resolution = .hundredsOfMilliseconds
            case let interval where interval <= 63 * 0.100:
                numberOfSteps = UInt8(interval * 10)
                resolution = .hundredsOfMilliseconds
            case let interval where interval <= 63 * 1.0:
                numberOfSteps = UInt8(interval)
                resolution = .seconds
            case let interval where interval <= 63 * 10.0:
                numberOfSteps = UInt8(interval / 10.0)
                resolution = .tensOfSeconds
            case let interval where interval <= 63 * 10 * 60.0:
                numberOfSteps = UInt8(interval / (10 * 60.0))
                resolution = .tensOfMinutes
            default:
                numberOfSteps = 0x3F
                resolution = .tensOfMinutes
            }
            self.interval = TimeInterval(resolution.toMilliseconds(steps: numberOfSteps)) / 1000.0
        }
        
        /// Creates the Period object.
        ///
        /// - parameters:
        ///   - steps: The number of steps, in range 0...63.
        ///   - resolution: The resolution of the number of steps.
        /// - since: 3.0
        public init(steps: UInt8, resolution: StepResolution) {
            self.numberOfSteps = steps
            self.resolution = resolution
            self.interval = TimeInterval(resolution.toMilliseconds(steps: steps)) / 1000.0
        }
        
        // MARK: - Codable
        
        private enum CodingKeys: String, CodingKey {
            case numberOfSteps
            case resolution
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let steps = try container.decode(UInt8.self, forKey: .numberOfSteps)
            guard steps <= 63 else {
                throw DecodingError.dataCorruptedError(forKey: .numberOfSteps, in: container,
                                                       debugDescription: "Number of steps must be in range 0 to 63.")
            }
            let milliseconds = try container.decode(Int.self, forKey: .resolution)
            let fixedMilliseconds = Period.fix(milliseconds, using: steps)
            guard let resolution = StepResolution(from: fixedMilliseconds) else {
                throw DecodingError.dataCorruptedError(forKey: .resolution, in: container,
                                                       debugDescription: "Unsupported resolution value: \(milliseconds). "
                                                                       + "The allowed values are: 100, 1000, 10000, and 600000.")
            }
            self.numberOfSteps = steps
            self.resolution = resolution
            self.interval = TimeInterval(resolution.toMilliseconds(steps: steps)) / 1000.0
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(numberOfSteps, forKey: .numberOfSteps)
            try container.encode(resolution.toMilliseconds(steps: 1), forKey: .resolution)
        }
    }
    
    /// Publication address for the Model. It's 4 or 32-character long
    /// hexadecimal string.
    internal let address: String
    /// Publication address for the model.
    public var publicationAddress: MeshAddress {
        // Warning: assuming hex address is valid!
        return MeshAddress(hex: address)!
    }
    /// An Application Key index, indicating which Application Key to
    /// use for the publication.
    public let index: KeyIndex
    /// An integer from 0 to 127 that represents the Time To Live (TTL)
    /// value for the outgoing publish message. 255 means default TTL value.
    public let ttl: UInt8
    /// The interval between subsequent publications.
    public let period: Period
    /// An integer 0 o 1 that represents whether master security
    /// (0) materials or friendship security material (1) are used.
    internal let credentials: Int
    /// The object describes the number of times a message is published and the
    /// interval between retransmissions of the published message.
    public let retransmit: Retransmit
    
    /// Creates an instance of Publish object.
    ///
    /// - parameters:
    ///   - destination: The publication address.
    ///   - applicationKey: The Application Key to encrypt messages with.
    ///   - friendshipCredentialsFlag: `True`, to use Friendship Security Material,
    ///                                `false` to use Master Security Material (default).
    ///   - ttl: Time To Live. The TTL is decremented every time the message is relayed,
    ///          until it reaches 1, after which the message is not relayed furhter.
    ///          Messages with TTL set to 0 are not relayed, and only sent to Nodes in
    ///          direct proximity. Use 0xFF to use Node's default TTL.
    ///   - period: Periodical publication interval. See ``Publish/Period-swift.struct``
    ///             for details.
    ///   - retransmit: The retransmission data. See ``Publish/Retransmit-swift.struct``
    ///                 for details.
    /// - since: 3.0
    public init(to destination: MeshAddress, using applicationKey: ApplicationKey,
                usingFriendshipMaterial friendshipCredentialsFlag: Bool, ttl: UInt8,
                period: Period, retransmit: Retransmit) {
        self.address = destination.hex
        self.index = applicationKey.index
        self.credentials = friendshipCredentialsFlag ? 1 : 0
        self.ttl = ttl
        self.period = period
        self.retransmit = retransmit
    }
    
    /// Creates an instance of Publish object.
    ///
    /// - parameters:
    ///   - destination: The publication address.
    ///   - applicationKey: The Application Key to encrypt messages with.
    ///   - friendshipCredentialsFlag: `True`, to use Friendship Security Material,
    ///                                `false` to use Master Security Material (default).
    ///   - ttl: Time To Live. The TTL is decremented every time the message is relayed,
    ///          until it reaches 1, after which the message is not relayed furhter.
    ///          Messages with TTL set to 0 are not relayed, and only sent to Nodes in
    ///          direct proximity. Use 0xFF to use Node's default TTL.
    ///   - periodSteps: Period steps, together with the period resolution are used to
    ///                  calculate the period interval. Value can be in range 0...63.
    ///                  Value 0 disables periodic publishing.
    ///   - periodResolution: The period resolution, used to calculate interval.
    ///                       Use ``StepResolution/hundredsOfMilliseconds`` when periodic
    ///                       publishing is disabled.
    ///   - retransmit: The retransmission data. See ``Publish/Retransmit-swift.struct``
    ///                 for details.
    @available(*, deprecated, message: "Use the constructor with 'period' parameter instead.")
    public init(to destination: MeshAddress, using applicationKey: ApplicationKey,
                usingFriendshipMaterial friendshipCredentialsFlag: Bool, ttl: UInt8,
                periodSteps: UInt8, periodResolution: StepResolution, retransmit: Retransmit) {
        self.address = destination.hex
        self.index = applicationKey.index
        self.credentials = friendshipCredentialsFlag ? 1 : 0
        self.ttl = ttl
        self.period = Period(steps: periodSteps, resolution: periodResolution)
        self.retransmit = retransmit
    }
    
    /// This initializer for disabling publication from a Model.
    ///
    /// - seeAlso: ``Publish/disabled``.
    /// - since: 3.0
    public init() {
        self.address = "0000"
        self.index = 0
        self.credentials = 0
        self.ttl = 0
        self.period = .disabled
        self.retransmit = .disabled
    }
    
    internal init(to destination: MeshAddress, withKeyIndex keyIndex: KeyIndex) {
        self.init(to: destination.hex, withKeyIndex: keyIndex,
                  friendshipCredentialsFlag: 0, ttl: 0xFF,
                  period: .disabled, retransmit: .disabled)
    }
    
    internal init(to destination: String, withKeyIndex keyIndex: KeyIndex,
                  friendshipCredentialsFlag: Int, ttl: UInt8,
                  period: Period, retransmit: Retransmit) {
        self.address = destination
        self.index = keyIndex
        self.credentials = friendshipCredentialsFlag
        self.ttl = ttl
        self.period = period
        self.retransmit = retransmit
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case address
        case index
        case ttl
        case period
        case credentials
        case retransmit
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let publishAddressAsString = try container.decode(String.self, forKey: .address)
        guard let _ = MeshAddress(hex: publishAddressAsString) else {
            throw DecodingError.dataCorruptedError(forKey: .address, in: container,
                                                   debugDescription: "Address must be 4-character hexadecimal string or UUID.")
        }
        self.address = publishAddressAsString
        self.index = try container.decode(KeyIndex.self, forKey: .index)
        let ttl = try container.decode(UInt8.self, forKey: .ttl)
        guard ttl <= 127 || ttl == 255 else {
            throw DecodingError.dataCorruptedError(forKey: .ttl, in: container,
                                                   debugDescription: "TTL must be in range 0-127 or 255.")
        }
        self.ttl = ttl
        
        // Period has changed from number of milliseconds, to an object
        // containing number of steps and the resolution in version 3.0.
        let millisecondsToPeriodConverter: (Int) throws -> Period = { milliseconds in
            switch milliseconds {
            case let value where value % 600000 == 0:
                return Period(steps: UInt8(value / 600000), resolution: .tensOfMinutes)
            case let value where value % 10000 == 0:
                return Period(steps: UInt8(value / 10000), resolution: .tensOfSeconds)
            case let value where value % 1000 == 0:
                return Period(steps: UInt8(value / 1000), resolution: .seconds)
            case let value where value % 100 == 0:
                return Period(steps: UInt8(value / 100), resolution: .hundredsOfMilliseconds)
            default:
                throw DecodingError.dataCorruptedError(forKey: .period, in: container,
                                                       debugDescription: "Unsupported period value: \(milliseconds).")
            }
        }
        self.period = try container.decode(Period.self, forKey: .period,
                                           orConvert: Int.self, forKey: .period,
                                           using: millisecondsToPeriodConverter)
        
        let flag = try container.decode(Int.self, forKey: .credentials)
        guard flag == 0 || flag == 1 else {
            throw DecodingError.dataCorruptedError(forKey: .credentials, in: container,
                                                   debugDescription: "Credentials must be 0 or 1.")
        }
        self.credentials = flag
        self.retransmit = try container.decode(Retransmit.self, forKey: .retransmit)
        guard retransmit.count <= 7 else {
            throw DecodingError.dataCorruptedError(forKey: .retransmit, in: container,
                                                   debugDescription: "Retransmit count must be in range 0-7.")
        }
        guard retransmit.interval >= 50 &&
              retransmit.interval <= 1600 &&
            (retransmit.interval % 50) == 0 else {
            throw DecodingError.dataCorruptedError(forKey: .retransmit, in: container,
                                                   debugDescription: "Retransmit interval must be in range 50-1600 ms in 50 ms steps.")
        }
    }
}

internal extension Publish {
    
    /// Creates a copy of the Publish object, but replaces the address
    /// with the given one. This method should be used to fill the virtual
    /// label after a ConfigModelPublicationStatus has been received.
    func withAddress(address: MeshAddress) -> Publish {
        return Publish(to: address.hex, withKeyIndex: index,
                       friendshipCredentialsFlag: credentials, ttl: ttl,
                       period: period,
                       retransmit: retransmit)
    }
    
}

extension Publish: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        if address == "0000" {
            return "Disabled"
        }
        return "\(publicationAddress) using App Key Index: \(index), ttl: \(ttl), flag: \(isUsingFriendshipSecurityMaterial), period: \(period), retransmit: \(retransmit)"
    }
    
}

extension Publish.Retransmit: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        if count == 0 {
            return "Disabled"
        }
        return "\(count) times every \(interval) ms"
    }
    
}

extension Publish.Period: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        if numberOfSteps == 0 {
            return "Disabled"
        }
        
        let value = Int(numberOfSteps)
        
        switch resolution {
        case .hundredsOfMilliseconds where numberOfSteps < 10:
            return "\(value * 100) ms"
        case .hundredsOfMilliseconds where numberOfSteps == 10:
            return "1 sec"
        case .hundredsOfMilliseconds:
            return "\(value / 10).\(value % 10) sec"
            
        case .seconds where numberOfSteps < 60:
            return "\(value) sec"
        case .seconds where numberOfSteps == 60:
            return "1 min"
        case .seconds:
            return "1 min \(value - 60) sec"
            
        case .tensOfSeconds where numberOfSteps < 6:
            return "\(value * 10) sec"
        case .tensOfSeconds where numberOfSteps % 6 == 0:
            return "\(value / 6) min"
        case .tensOfSeconds:
            return "\(value / 6) min \(value % 6 * 10) sec"
            
        case .tensOfMinutes where numberOfSteps < 6:
            return "\(value * 10) min"
        case .tensOfMinutes where numberOfSteps % 6 == 0:
            return "\(value / 6) h"
        case .tensOfMinutes:
            return "\(value / 6) h \(value % 6 * 10) min"
        }
    }
    
}

private extension Publish.Period {
    
    /// This method implements a workaround for importing publish resolution
    /// exported from nRF Mesh in version 3.0.1 or older, where it was multipled
    /// by the number of steps.
    ///
    /// E.g. 40 seconds would be exported as:
    /// ```
    /// "period": {
    ///    "numberOfSteps": 40,
    ///    "resolution": 40000 // instead of 1000
    /// }
    /// ```
    static func fix(_ milliseconds: Int, using steps: UInt8) -> Int {
        switch milliseconds {
        case 0,
             _ where steps == 0:
            // If resolution or steps were set to 0, set resolution to
            // hundreds of milliseconds.
            return 100
        case 100, 1000, 10000, 600000:
            // Those are the valid values. Keep it as it is.
            return milliseconds
        case _ where milliseconds % Int(steps) == 0:
            // If the imported value is a multiplication of steps, divide it.
            // Steps are no longer 0 at this point, so it's safe.
            return milliseconds / Int(steps)
        default:
            // An invalid value was imported, that cannot be converted.
            // Setting it to 0 will generate an error below.
            return 0
        }
    }
    
}
