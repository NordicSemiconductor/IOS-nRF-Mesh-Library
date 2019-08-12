//
//  MeshMessage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 25/05/2019.
//

import Foundation

public enum MeshMessageSecurity {
    /// Message will be sent with 32-bit Transport MIC.
    case low
    /// Message will be sent with 64-bit Transport MIC.
    /// Unsegmented messages cannot be sent with this option.
    case high
    
    /// Returns the Transport MIC size in bytes: 4 for 32-bit
    /// or 8 for 64-bit size.
    internal var transportMicSize: UInt8 {
        switch self {
        case .low:  return 4
        case .high: return 8
        }
    }
}

public protocol MeshMessage {
    /// The message Op Code.
    static var opCode: UInt32 { get }
    /// Message parameters as Data.
    var parameters: Data? { get }
    /// Returns whether the message should be sent or has been sent using
    /// 32-bit or 64-bit TransMIC value. By default `.low` is returned.
    ///
    /// Only Segmented Access Messages can use 64-bit MIC. If the payload
    /// is shorter than 11 bytes, make sure you return `true` from
    /// `isSegmented`, otherwise this field will be ignored.
    var security: MeshMessageSecurity { get }
    /// Returns whether the message should be sent or was sent as
    /// Segmented Access Message. By default, this parameter returns
    /// `true` if payload (Op Code and parameters) size is longer than 11 bytes
    /// and `false` otherwise.
    ///
    /// To force segmentation for shorter messages return `true` despite
    /// payload length. If payload size is longer than 11 bytes this
    /// field is not checked as the message must be segmented.
    var isSegmented: Bool { get }
    
    /// This initializer should construct the message based on the received
    /// parameters.
    ///
    /// - parameter parameters: The Access Layer parameters.
    init?(parameters: Data)
}

public protocol StatusMessage: MeshMessage {
    /// Returns whether the operation was successful or not.
    var isSuccess: Bool { get }
    
    /// The status as String.
    var message: String { get }
}

// MARK: - Default values

public extension MeshMessage {
    
    var security: MeshMessageSecurity {
        return .low
    }
    
    var isSegmented: Bool {
        return accessPdu.count > 11
    }
    
}

// MARK: - Private API

internal extension MeshMessage {
    
    /// The Access Layer PDU data that will be sent.
    var accessPdu: Data {
        let opCode = Self.opCode
        
        // Op Code 0b01111111 is invalid. We will ignore this case here now and send as single byte OpCode.
        if opCode < 0x80 {
            return Data([UInt8(opCode & 0xFF)]) + parameters
        }
        if opCode < 0x4000 || opCode & 0xFFFC00 == 0x8000 {
            return Data([UInt8(0x80 | ((opCode >> 8) & 0x3F)), UInt8(opCode & 0xFF)]) + parameters
        }
        return Data([UInt8(0xC0 | ((opCode >> 16) & 0x3F)), UInt8((opCode >> 8) & 0xFF), UInt8(opCode & 0xFF)]) + parameters
    }
    
}
