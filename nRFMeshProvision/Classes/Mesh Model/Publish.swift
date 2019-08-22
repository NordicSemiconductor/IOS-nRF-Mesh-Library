//
//  Publish.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 27/03/2019.
//

import Foundation

public struct Publish: Codable {
    
    /// The object is used to describe the number of times a message is
    /// published and the interval between retransmissions of the published
    /// message.
    public struct Retransmit: Codable {
        /// Number of retransmissions for network messages.
        /// The value is in range from 0 to 7, where 0 means no retransmissions.
        public let count: UInt8
        /// The interval (in milliseconds) between retransmissions (50...3200 with step 50).
        public let interval: UInt16
        /// Retransmission steps, from 0 to 31. Use `interval` to get the interval in ms.
        public var steps: UInt8 {
            return UInt8((interval / 50) - 1)
        }
        
        internal init() {
            count = 0
            interval = 50
        }
        
        public init(publishRetransmitCount: UInt8, intervalSteps: UInt8) {
            count    = publishRetransmitCount
            // Interval is in 50 ms steps.
            interval = UInt16(intervalSteps + 1) * 50 // ms
        }
    }
    
    /// Publication address for the Model. It's 4 or 32-character long
    /// hexadecimal string.
    private let address: String
    /// Publication address for the model.
    public var publicationAddress: MeshAddress {
        // Warning: assuming hex address is valid!
        return MeshAddress(hex: address)!
    }
    /// An Application Key index, indicating which Applicaiton Key to
    /// use for the publication.
    public let index: KeyIndex
    /// An integer from 0 to 127 that represents the Time To Live (TTL)
    /// value for the outgoing publish message. 255 means default TTL value.
    public let ttl: UInt8
    /// The interval (in milliseconds) between subsequent publications.
    internal let period: Int
    /// The number of steps, in range 0...63.
    public let periodSteps: UInt8
    /// The resolution of the number of steps.
    public let periodResolution: StepResolution
    /// Returns the interval between subsequent publications
    /// in seconds.
    public var publicationInterval: TimeInterval {
        return TimeInterval(period) / 1000.0
    }
    /// An integer 0 o 1 that represents whether master security
    /// (0) materials or friendship security material (1) are used.
    internal let credentials: Int
    /// The object describes the number of times a message is published and the
    /// interval between retransmissions of the published message.
    public internal(set) var retransmit: Retransmit
    
    /// Creates an instance of Publish object.
    ///
    /// - parameters:
    ///   - destination: The publication address.
    ///   - applicationKey: The Application Key that will be used to send messages.
    ///   - friendshipCredentialsFlag: `True`, to use Friendship Security Material,
    ///                                `false` to use Master Security Material.
    ///   - ttl: Time to live. Use 0xFF to use Node's default TTL.
    ///   - periodSteps: Period steps, together with `periodResolution` are used to
    ///                  calculate period interval. Value can be in range 0...63.
    ///                  Value 0 disables periodic publishing.
    ///   - periodResolution: The period resolution, used to calculate interval.
    ///                       Use `._100_milliseconds` when periodic publishing is
    ///                       disabled.
    ///   - retransmit: The retransmission data. See `Retransmit` for details.
    public init(to destination: MeshAddress, using applicationKey: ApplicationKey,
                usingFriendshipMaterial friendshipCredentialsFlag: Bool, ttl: UInt8,
                periodSteps: UInt8, periodResolution: StepResolution, retransmit: Retransmit) {
        self.address = destination.hex
        self.index = applicationKey.index
        self.credentials = friendshipCredentialsFlag ? 1 : 0
        self.ttl = ttl
        self.periodSteps = periodSteps
        self.periodResolution = periodResolution
        self.period = periodResolution.toPeriod(steps: periodSteps)
        self.retransmit = retransmit
    }
    
    /// This initializer should be used to remove the publication from a Model.
    internal init() {
        self.address = "0000"
        self.index = 0
        self.credentials = 0
        self.ttl = 0
        self.periodSteps = 0
        self.periodResolution = .hundredsOfMilliseconds
        self.period = 0
        self.retransmit = Retransmit(publishRetransmitCount: 0, intervalSteps: 0)
    }
    
    internal init(to destination: String, withKeyIndex keyIndex: KeyIndex,
                  friendshipCredentialsFlag: Int, ttl: UInt8,
                  periodSteps: UInt8, periodResolution: StepResolution, retransmit: Retransmit) {
        self.address = destination
        self.index = keyIndex
        self.credentials = friendshipCredentialsFlag
        self.ttl = ttl
        self.periodSteps = periodSteps
        self.periodResolution = periodResolution
        self.period = periodResolution.toPeriod(steps: periodSteps)
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
        address = try container.decode(String.self, forKey: .address)
        index = try container.decode(KeyIndex.self, forKey: .index)
        ttl = try container.decode(UInt8.self, forKey: .ttl)
        period = try container.decode(Int.self, forKey: .period)
        switch period {
        case let period where period % 600000 == 0:
            periodResolution = .tensOfMinutes
            periodSteps = UInt8(period / 600000)
        case let period where period % 10000 == 0:
            periodResolution = .tensOfSeconds
            periodSteps = UInt8(period / 10000)
        case let period where period % 1000 == 0:
            periodResolution = .seconds
            periodSteps = UInt8(period / 1000)
        default:
            periodResolution = .hundredsOfMilliseconds
            periodSteps = UInt8(period / 100)
        }
        let flag = try container.decode(Int.self, forKey: .credentials)
        guard flag == 0 || flag == 1 else {
            throw DecodingError.dataCorruptedError(forKey: .credentials, in: container,
                                                   debugDescription: "Credentials must be 0 or 1")
        }
        credentials = flag
        retransmit = try container.decode(Retransmit.self, forKey: .retransmit)
    }
}

public extension Publish {
    
    /// Returns whether master security materials are used.
    var isUsingMasterSecurityMaterial: Bool {
        return credentials == 0
    }
    
    /// Returns whether friendship security materials are used.
    var isUsingFriendshipSecurityMaterial: Bool {
        return credentials == 1
    }
    
}

internal extension Publish {
    
    /// Creates a copy of the Publish object, but replaces the address
    /// with the given one. This method should be used to fill the virtual
    /// label after a ConfigModelPublicationStatus has been received.
    func withAddress(address: MeshAddress) -> Publish {
        return Publish(to: address.hex, withKeyIndex: index,
                       friendshipCredentialsFlag: credentials, ttl: ttl,
                       periodSteps: periodSteps, periodResolution: periodResolution,
                       retransmit: retransmit)
    }
    
}

extension Publish: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        if address == "0000" {
            return "Disabled"
        }
        return "\(publicationAddress) using App Key Index: \(index), ttl: \(ttl), flag: \(isUsingFriendshipSecurityMaterial), period: \(publicationInterval) sec, retransmit: \(retransmit)"
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
