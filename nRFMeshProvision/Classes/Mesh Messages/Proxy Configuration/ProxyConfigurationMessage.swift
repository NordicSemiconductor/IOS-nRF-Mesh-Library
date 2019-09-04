//
//  ProxyConfigurationMessage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 03/09/2019.
//

import Foundation

public protocol ProxyConfigurationMessage: BaseMeshMessage {
    /// The message Op Code.
    var opCode: UInt8 { get }
}

/// A type of a Proxy Configuration message which opcode is known
/// during compilation time.
public protocol StaticProxyConfigurationMessage: ProxyConfigurationMessage {
    /// The message Op Code.
    static var opCode: UInt8 { get }
}

// MARK: - Default values

public extension StaticProxyConfigurationMessage {
    
    var opCode: UInt8 {
        return Self.opCode
    }
    
}
