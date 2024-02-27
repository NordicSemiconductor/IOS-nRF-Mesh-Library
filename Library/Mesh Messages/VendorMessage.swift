/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

/// A base protocol for vendor messages.
///
/// Vendor messages have 24-bit long Op Code,
/// of which 16 least significant bits contains the Company ID
/// and 6 least significant bits of the most significant byte
/// are the vendor Op Code.
public protocol VendorMessage: MeshMessage {
    // No additional fields.
}

/// A base protocol for unacknowledged vendor message.
public protocol UnacknowledgedVendorMessage: VendorMessage, UnacknowledgedMeshMessage {
    // No additional fields.
}

/// The base class for vendor response messages.
public protocol VendorResponse: MeshResponse, UnacknowledgedVendorMessage {
    // No additional fields.
}

/// A base protocol for acknowledged vendor message.
public protocol AcknowledgedVendorMessage: VendorMessage, AcknowledgedMeshMessage {
    // No additional fields.
}

/// A base protocol for static vendor message.
public protocol StaticVendorMessage: VendorMessage, StaticMeshMessage {
    // No additional fields.
}

/// A base protocol for static unacknowledged vendor message.
public protocol StaticUnacknowledgedVendorMessage: StaticVendorMessage, UnacknowledgedMeshMessage {
    // No additional fields.
}

/// The base class for vendor response messages.
public protocol StaticVendorResponse: StaticMeshResponse, StaticUnacknowledgedVendorMessage {
    // No additional fields.
}

/// A base protocol for static acknowledged vendor message.
public protocol StaticAcknowledgedVendorMessage: StaticVendorMessage, StaticAcknowledgedMeshMessage {
    // No additional fields.
}

/// A base protocol for vendor status message.
public protocol VendorStatusMessage: UnacknowledgedVendorMessage, StatusMessage {
    // No additional fields.
}

public extension VendorMessage {
    
    /// The Op Code as defined by the company.
    ///
    /// There are 64 3-octet Op Codes available per company identifier.
    /// Op Code is encoded in the 6 least significant
    /// bits of the most significant octet of the message Op Code.
    var vendorOpCode: UInt8 {
        return UInt8(opCode >> 16) & 0x3F
    }
    
    /// The Company Identifiers are 16-bit values defined by the
    /// Bluetooth SIG and are coded into the second and third octets
    /// of the 3-octet Op Code.
    var companyIdentifier: UInt16 {
        return UInt16(opCode & 0xFFFF).bigEndian
    }
    
}

public extension Array where Element == StaticVendorMessage.Type {
    
    /// A helper method that can create a map of message types required
    /// by the ``ModelDelegate`` from a list of ``StaticVendorMessage``s.
    ///
    /// - returns: A map of message types.
    func toMap() -> [UInt32 : MeshMessage.Type] {
        return (self as [StaticMeshMessage.Type]).toMap()
    }
    
}
