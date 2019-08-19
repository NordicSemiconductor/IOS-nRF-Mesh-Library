//
//  UnknownMessage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 16/08/2019.
//

import Foundation

public struct UnknownMessage: MeshMessage {
    // The opcode is set when the message is received. Initally it is set
    // to 0, as the constructor takes only parameters.
    public internal(set) var opCode: UInt32 = 0
    
    public let parameters: Data?
    
    public init?(parameters: Data) {
        self.parameters = parameters
    }    
    
}

extension UnknownMessage: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        let value = parameters?.hex ?? "nil"
        return "UnknownMessage(opCode: \(opCode), parameters: \(value))"
    }
    
}
