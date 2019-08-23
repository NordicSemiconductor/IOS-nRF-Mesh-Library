//
//  GenericPowerRangeSet.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 23/08/2019.
//

import Foundation

public struct GenericPowerRangeSet: GenericMessage {
    public static let opCode: UInt32 = 0x8221
    
    public var parameters: Data? {
        return Data() + range.lowerBound + range.upperBound
    }
    
    /// The value of the Generic Power Range state.
    public let range: ClosedRange<UInt16>
    
    /// Creates the Generic Power Range Set message.
    ///
    /// - parameter range: The value of the Generic Power Range state.
    public init(range: ClosedRange<UInt16>) {
        self.range = range
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 4 else {
            return nil
        }
        range = parameters.read(fromOffset: 0)...parameters.read(fromOffset: 2)
    }
    
}
