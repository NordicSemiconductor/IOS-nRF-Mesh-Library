//
//  ControlMessage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 31/05/2019.
//

import Foundation

internal protocol ControlMessage {
    /// Message Op Code.
    var opCode: UInt8 { get }
    /// Message parameters.
    var parameters: Data { get }
    
}
