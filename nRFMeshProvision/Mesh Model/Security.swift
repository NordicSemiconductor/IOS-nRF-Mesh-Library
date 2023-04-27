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

/// The type representing Security level for the subnet on which a
/// node has been originally provisioned.
public enum Security: String, Codable {
    /// A key is considered insecure if at least one Node has been provisioned
    /// without using Out-Of-Band Public Key exchange. This Node is also considered
    /// insecure.
    case insecure = "insecure"
    /// A key is considered secure if all Nodes which know the key have been
    /// provisioned using Secure Procedure, that is using Out-Of-Band Public Key.
    case secure   = "secure"
    
    // In version 3.0 of the library the string security values changed
    // from "high" and "low" to "secure" and "insecure".
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        switch value {
        case "secure", "high":
            self = .secure
        case "insecure", "low":
            self = .insecure
        default:
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Security must be 'secure' or 'insecure'.")
        }
    }
}

extension Security: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .insecure: return "Insecure"
        case .secure:   return "Secure"
        }
    }
    
}
