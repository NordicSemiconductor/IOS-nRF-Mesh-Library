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
    /// Source Address.
    var source: Address { get }
    /// Destination Address.
    var destination: Address { get }
    /// The Network Key used to decode/encode the PDU.
    var networkKey: NetworkKey { get }
    /// Message type.
    var type: LowerTransportPduType { get }
    /// The raw data of Lower Transport Layer PDU.
    var transportPdu: Data { get }
    /// The raw data of Upper Transport Layer PDU.
    var upperTransportPdu: Data { get }
}

extension LowerTransportPduType: CustomDebugStringConvertible {
    
    var debugDescription: String {
        switch self {
        case .accessMessage:  return "Access Message"
        case .controlMessage: return "Control Message"
        }
    }
    
}
