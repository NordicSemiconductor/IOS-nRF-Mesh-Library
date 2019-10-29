//
//  AccessPdu.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 18/06/2019.
//

import Foundation

internal struct AccessPdu {
    /// The Mesh Message that is being sent, or `nil`, when the message
    /// was received.
    let message: MeshMessage?
    /// The local Element that is sending the message, or `nil` when the
    /// message was received.
    let localElement: Element?
    /// Whether sending this message has been initiated by the user.
    /// Status of automatic replies will not be reported to the app.
    let userInitiated: Bool
    
    /// Source Address.
    let source: Address
    /// Destination Address.
    let destination: MeshAddress
    /// Message Op Code.
    let opCode: UInt32
    /// Message parameters as Data.
    let parameters: Data
    
    /// The Access Layer PDU data that will be sent.
    let accessPdu: Data
    
    /// Whether the outgoind message will be sent as segmented, or not.
    var isSegmented: Bool {
        guard let message = message else {
            return false
        }
        return accessPdu.count > 11 || message.isSegmented
    }
    /// Number of packets for this PDU.
    ///
    /// Number of Packets | Maximum useful access payload size (octets)
    ///                   | 32 bit TransMIC  | 64 bit TransMIC
    /// ------------------+------------------+-------------------------
    /// 1                 | 11 (unsegmented) | n/a
    /// 1                 | 8 (segmented)    | 4 (segmented)
    /// 2                 | 20               | 16
    /// 3                 | 32               | 28
    /// n                 | (n×12)-4         | (n×12)-8
    /// 32                | 380              | 376
    var segmentsCount: Int {
        guard let message = message else {
            return 0
        }
        if !isSegmented {
            return 1
        }
        switch message.security {
        case .low:
            return 1 + (accessPdu.count + 3) / 12
        case .high:
            return 1 + (accessPdu.count + 7) / 12
        }
    }
    
    init?(fromUpperTransportPdu pdu: UpperTransportPdu) {
        message = nil
        localElement = nil
        userInitiated = false
        source = pdu.source
        destination = MeshAddress(pdu.destination)
        accessPdu = pdu.accessPdu
        
        // At least 1 octet is required.
        guard pdu.accessPdu.count >= 1 else {
            return nil
        }
        let octet0 = pdu.accessPdu[0]
        
        // Opcode 0b01111111 is reseved for future use.
        guard octet0 != 0b01111111 else {
            return nil
        }
        
        // 1-octet Opcodes.
        if (octet0 & 0x80) == 0 {
            opCode = UInt32(octet0)
            parameters = pdu.accessPdu.subdata(in: 1..<pdu.accessPdu.count)
            return
        }
        // 2-octet Opcodes.
        if (octet0 & 0x40) == 0 {
            // At least 2 octets are required.
            guard pdu.accessPdu.count >= 2 else {
                return nil
            }
            let octet1 = pdu.accessPdu[1]
            opCode = UInt32(octet0) << 8 | UInt32(octet1)
            parameters = pdu.accessPdu.subdata(in: 2..<pdu.accessPdu.count)
            return
        }
        // 3-octet Opcodes.
        // At least 3 octets are required.
        guard pdu.accessPdu.count >= 3 else {
            return nil
        }
        let octet1 = pdu.accessPdu[1]
        let octet2 = pdu.accessPdu[2]
        opCode = UInt32(octet0) << 16 | UInt32(octet1) << 8 | UInt32(octet2)
        parameters = pdu.accessPdu.subdata(in: 3..<pdu.accessPdu.count)
    }
    
    init(fromMeshMessage message: MeshMessage,
         sentFrom localElement: Element, to destination: MeshAddress,
         userInitiated: Bool) {
        self.message = message
        self.localElement = localElement
        self.userInitiated = userInitiated
        self.source = localElement.unicastAddress
        self.destination = destination
        
        self.opCode = message.opCode
        self.parameters = message.parameters ?? Data()
        
        // Op Code 0b01111111 is invalid. We will ignore this case here
        // for now and send as a single byte OpCode.
        // TODO: Handle 0b0111111 opcode correctly.
        switch opCode {
        case let opCode where opCode < 0x80:
            accessPdu = Data([UInt8(opCode & 0xFF)]) + parameters
        case let opCode where opCode < 0x4000 || opCode & 0xFFFC00 == 0x8000:
            accessPdu = Data([UInt8(0x80 | ((opCode >> 8) & 0x3F)), UInt8(opCode & 0xFF)]) + parameters
        default:
            accessPdu = Data([
                UInt8(0xC0 | ((opCode >> 16) & 0x3F)),
                UInt8((opCode >> 8) & 0xFF),
                UInt8(opCode & 0xFF)
                ]) + parameters
        }
    }
}

extension AccessPdu: CustomDebugStringConvertible {
    
    var debugDescription: String {
        let hexOpCode = String(format: "%2X", opCode)
        return "Access PDU (opcode: 0x\(hexOpCode), parameters: 0x\(parameters.hex))"
    }
    
}
