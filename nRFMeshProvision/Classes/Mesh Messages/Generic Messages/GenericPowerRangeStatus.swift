//
//  GenericPowerRangeStatus.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 23/08/2019.
//

import Foundation

public struct GenericPowerRangeStatus: GenericStatusMessage {
    public static let opCode: UInt32 = 0x821E
    
    public var parameters: Data? {
        return Data([status.rawValue]) + range.lowerBound + range.upperBound
    }
    
    public var status: GenericMessageStatus
    /// The value of the Generic Power Range state.
    public let range: ClosedRange<UInt16>
    
    /// Creates the Generic Power Range Status message.
    ///
    /// - parameter range: The value of the Generic Power Range state.
    public init(report range: ClosedRange<UInt16>) {
        self.status = .success
        self.range = range
    }
    
    /// Creates the Generic Power Range Status message.
    ///
    /// - parameter status: Status Code for the requesting message.
    /// - parameter request: The request received.
    public init(_ status: GenericMessageStatus, for request: GenericPowerRangeSet) {
        self.status = status
        self.range = request.range
    }
    
    /// Creates the Generic Power Range Status message.
    ///
    /// - parameter status: Status Code for the requesting message.
    /// - parameter request: The request received.
    public init(_ status: GenericMessageStatus, for request: GenericPowerRangeSetUnacknowledged) {
        self.status = status
        self.range = request.range
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 5 else {
            return nil
        }
        guard let status = GenericMessageStatus(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        range = parameters.read(fromOffset: 1)...parameters.read(fromOffset: 3)
    }
    
}

