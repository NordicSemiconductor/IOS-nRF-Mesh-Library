//
//  UnknownMessage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 16/08/2019.
//

import Foundation

public struct UnknownMessage: MeshMessage {
    // The op code for an unknown message is not know before it's
    // received. A field will be set instead.
    public static let opCode: UInt32 = 0xFFFFFFFF
    
    /// The message Op Code.
    public internal(set) var opCode: UInt32!
    public let parameters: Data?
    
    public init?(parameters: Data) {
        self.parameters = parameters
    }    
    
}

extension UnknownMessage: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        let value = parameters?.hex ?? "nil"
        return "UnknownMessage(opCode: \(opCode!), parameters: \(value))"
    }
    
}
