//
//  LowerTransportPdu.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 31/05/2019.
//

import Foundation


internal enum LowerTransportPduType: UInt8 {
    case accessMessage  = 0
    case controlMessage = 1
}

internal protocol LowerTransportPdu {
    /// Source Address. This is set to `nil` for outgoing messages,
    /// where the Network Layer will set the local Provisioner's
    /// Unicast Address as source address.
    var source: Address? { get }
    /// Destination Address.
    var destination: Address { get }
    /// Message type.
    var type: LowerTransportPduType { get }
    /// The raw data of Lower Transport Layer PDU.
    var transportPdu: Data { get }
}

extension LowerTransportPduType: CustomDebugStringConvertible {
    
    var debugDescription: String {
        switch self {
        case .accessMessage:  return "Access Message"
        case .controlMessage: return "Control Message"
        }
    }
    
}
