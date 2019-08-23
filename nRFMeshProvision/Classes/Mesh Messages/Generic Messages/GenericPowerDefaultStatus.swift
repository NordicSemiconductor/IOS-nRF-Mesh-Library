//
//  GenericPowerDefaultStatus.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 23/08/2019.
//

import Foundation

public struct GenericPowerDefaultStatus: GenericMessage {
    public static let opCode: UInt32 = 0x821C
    
    public var parameters: Data? {
        return Data() + power
    }
    
    /// The value of the Generic Power Default state.
    public let power: UInt16
    
    /// Creates the Generic Power Default Status message.
    ///
    /// - parameter power: The value of the Generic Power Default state.
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
