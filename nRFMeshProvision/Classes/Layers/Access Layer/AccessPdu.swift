//
//  AccessPdu.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 18/06/2019.
//

import Foundation

internal struct AccessPdu {
    /// Source Address.
    let source: Address
    /// Destination Address.
    let destination: Address
    /// Message Op Code.
    let opCode: UInt32
    /// Message parameters as Data.
    let parameters: Data
    
    init?(fromUpperTransportPdu pdu: UpperTransportPdu) {
        source = pdu.source
        destination = pdu.destination
        
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
}

extension AccessPdu: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "Access PDU (\(source.hex)->\(destination.hex)): Op Code: \(opCode), 0x\(parameters.hex)"
    }
    
}
