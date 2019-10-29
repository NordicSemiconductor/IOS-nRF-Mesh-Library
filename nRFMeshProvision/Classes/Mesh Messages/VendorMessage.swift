//
//  VendorMessage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 16/08/2019.
//

import Foundation

public protocol VendorMessage: MeshMessage {
    // No additional fields.
}

public protocol AcknowledgedVendorMessage: VendorMessage, AcknowledgedMeshMessage {
    // No additional fields.
}

public protocol StaticVendorMessage: VendorMessage, StaticMeshMessage {
    // No additional fields.
}

public protocol AcknowledgedStaticVendorMessage: StaticVendorMessage, StaticAcknowledgedMeshMessage {
    // No additional fields.
}

public protocol VendorStatusMessage: StatusMessage {
    // No additional fields.
}

public extension VendorMessage {
    
    /// The Op Code as defined by the company.
    ///
    /// There are 64 3-octet opcodes available per company identifier.
    /// Op Code is encoded in the 6 least significant
    /// bits of the first octet of the message Op Code.
    var opCode: UInt8 {
        return UInt8(opCode >> 16) & 0x3F
    }
    
    /// The Company Identifiers are 16-bit values defined by the
    /// Bluetooth SIG and are coded into the second and third octets
    /// of the 3-octet opcodes
    var companyIdentifier: UInt16 {
        return UInt16(opCode & 0xFFFF).bigEndian
    }
    
}

public extension Array where Element == StaticVendorMessage.Type {
    
    /// A helper method that can create a map of message types required
    /// by the `ModelDelegate` from a list of `StaticVendorMessage`s.
    ///
    /// - returns: A map of message types.
    func toMap() -> [UInt32 : MeshMessage.Type] {
        return (self as [StaticMeshMessage.Type]).toMap()
    }
    
}
