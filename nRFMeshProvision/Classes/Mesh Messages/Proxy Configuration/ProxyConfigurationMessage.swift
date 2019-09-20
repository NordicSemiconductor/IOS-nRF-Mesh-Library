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

/// The base class for acknowledged messages.
///
/// An acknowledged message is transmitted and acknowledged by each
/// receiving element by responding to that message. The response is
/// typically a status message. If a response is not received within
/// an arbitrary time period, the message will be retransmitted
/// automatically until the timeout occurs.
public protocol AcknowledgedProxyConfigurationMessage: ProxyConfigurationMessage {
    /// The Op Code of the response message.
    var responseOpCode: UInt8 { get }
}

public protocol StaticAcknowledgedProxyConfigurationMessage:
    AcknowledgedProxyConfigurationMessage, StaticProxyConfigurationMessage {
    /// The Type of the response message.
    static var responseType: StaticProxyConfigurationMessage.Type { get }
}

// MARK: - Default values

public extension StaticProxyConfigurationMessage {
    
    var opCode: UInt8 {
        return Self.opCode
    }
    
}

public extension StaticAcknowledgedProxyConfigurationMessage {
    
    var responseOpCode: UInt8 {
        return Self.responseType.opCode
    }
    
}
