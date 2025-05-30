/*
* Copyright (c) 2025, Nordic Semiconductor
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
import NordicMesh

struct PairingResponse: StaticVendorResponse {
    // The Op Code consists of:
    // 0xC0-0000 - Vendor Op Code bitmask
    // 0x11-0000 - The Op Code defined by...
    // 0x00-5900 - Nordic Semiconductor ASA company ID (in Little Endian) as defined here:
    //             https://www.bluetooth.com/specifications/assigned-numbers/company-identifiers/
    static let opCode: UInt32 = 0xD15900 // The same Op Code as PairingRequest!
    
    var parameters: Data? {
        let passkeyData = Data() + passkey
        return Data([0x01, status]) + passkeyData.dropFirst()
    }
    /// Message status.
    let status: UInt8
    /// The passkey to be used for pairing.
    let passkey: Int
    
    init(status: UInt8, passkey: Int) {
        self.status = status
        self.passkey = passkey
    }
    
    init?(parameters: Data) {
        guard parameters.count == 5 && parameters[0] == 0x01 else {
            return nil
        }
        status = parameters[1]
        passkey = Int(parameters[2]) | Int(parameters[3]) << 8 | Int(parameters[4]) << 16
    }
    
}
