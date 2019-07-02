//
//  Publish.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 27/03/2019.
//

import Foundation

public class Publish: Codable {
    
    /// The object is used to describe the number of times a message is
    /// published and the interval between retransmissions of the published
    /// message.
    public class Retransmit: Codable {
        /// Number of retransmissions for network messages.
        /// The value is in range from 1 to 8.
        public internal(set) var count: UInt8
        /// The interval (in milliseconds) between retransmissions.
        public internal(set) var interval: UInt16
        
        internal init() {
            self.count = 0
            self.interval = 1000
        }
        
        internal init(publishedRetransmitCount: UInt8, intervalSteps: UInt16) {
            self.count    = publishedRetransmitCount
            // Interval is in 50 ms steps.
            self.interval = (intervalSteps + 1) * 50 // ms
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
    /// An Application Key index, indicating which Applicaiton Key to
    /// use for the publication.
    internal let index: KeyIndex
    /// An integer from 0 to 127 that represents the Time To Leave (TTL)
    /// value for the outgoing publish message.
    public internal(set) var ttl: UInt8 = 5 {
        didSet {
            if ttl > 127 {
                ttl = 127
            }
        }
    }
    /// The interval (in milliseconds) between subsequent publications.
    internal var period: Int = 5
    /// Returns the interval between subsequent publications
    /// in seconds.
    public var publicationInterval: TimeInterval {
        return TimeInterval(period) / 1000.0
    }
    /// An integer 0 o 1 that represents whether master security
    /// (0) materials or friendship security material (1) are used.
    internal var credentials: Int = 0 {
        didSet {
            if credentials > 1 {
                // Reset value if too high.
                credentials = 0
            }
        }
    }
    /// The object describes the number of times a message is published and the
    /// interval between retransmissions of the published message.
    public internal(set) var retransmit: Retransmit
    
    internal init(address: String, index: KeyIndex) {
        self.address = address
        self.index = index
        self.retransmit = Retransmit()
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
