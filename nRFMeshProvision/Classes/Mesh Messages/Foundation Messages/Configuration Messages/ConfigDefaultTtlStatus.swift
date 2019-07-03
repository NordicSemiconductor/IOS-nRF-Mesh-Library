//
//  ConfigDefaultTtlStatus.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 25/06/2019.
//

import Foundation

public struct ConfigDefaultTtlStatus: ConfigMessage {
    public static let opCode: UInt32 = 0x800E
    
    public var parameters: Data? {
        return Data([ttl])
    }
    
    public var isSegmented: Bool {
        return false
    }
    
    /// The Time To Live (TTL) value. Valid value is in range 1...127.
    public let ttl: UInt8
    
    public init(ttl: UInt8) {
        self.ttl = ttl
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 1 else {
            return nil
        }
        ttl = parameters[0]
    }
    
}
