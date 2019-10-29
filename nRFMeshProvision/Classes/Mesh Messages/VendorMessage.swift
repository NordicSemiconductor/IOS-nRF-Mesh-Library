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
