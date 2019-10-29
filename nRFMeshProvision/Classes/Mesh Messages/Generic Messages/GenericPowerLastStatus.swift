//
//  GenericPowerLastStatus.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 23/08/2019.
//

import Foundation

public struct GenericPowerLastStatus: GenericMessage {
    public static let opCode: UInt32 = 0x821A
    
    public var parameters: Data? {
        return Data() + power
    }
    
    /// The value of the Generic Power Last state.
    public let power: UInt16
    
    /// Creates the Generic Power Last Status message.
    ///
    /// - parameter power: The value of the Generic Power Last state.
    public init(power: UInt16) {
        self.power = power
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 2 else {
            return nil
        }
        power = parameters.read(fromOffset: 0)
    }
    
}

