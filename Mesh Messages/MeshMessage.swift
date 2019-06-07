//
//  MeshMessage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 25/05/2019.
//

import Foundation

public protocol MeshMessage {
    /// The message Op Code.
    var opCode: UInt32 { get }
    /// The message parameters as Data.
    var parameters: Data { get }
}

internal extension MeshMessage {
    
    /// The Access Layer PDU data that will be sent.
    var accessPdu: Data {
        // Op Code 0b01111111 is invalid. We will ignore this case here now and send as single byte OpCode.
        if opCode < 0x80 {
            return Data([UInt8(opCode & 0xFF)]) + parameters
        }
        if opCode < 0x4000 {
            return Data([UInt8(0x80 | ((opCode >> 8) & 0x3F)), UInt8(opCode & 0xFF)]) + parameters
        }
        return Data([UInt8(0xC0 | ((opCode >> 16) & 0x3F)), UInt8((opCode >> 8) & 0xFF), UInt8(opCode & 0xFF)]) + parameters
    }
    
}
