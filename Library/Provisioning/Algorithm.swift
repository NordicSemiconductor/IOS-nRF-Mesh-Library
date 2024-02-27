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

/// The algorithm used for calculating Device Key.
public enum Algorithm {
    /// FIPS P-256 Elliptic Curve algorithm will be used to calculate the
    /// shared secret.
    ///
    /// This has been replaced with ``Algorithm/BTM_ECDH_P256_CMAC_AES128_AES_CCM``.
    @available(*, deprecated, renamed: "BTM_ECDH_P256_CMAC_AES128_AES_CCM")
    case fipsP256EllipticCurve
    /// BTM ECDH P256 CMAC AES128 AES CCM algorithm will be used to calculate the
    /// shared secret.
    case BTM_ECDH_P256_CMAC_AES128_AES_CCM
    /// BTM ECDH P256 HMAC SHA256 AES CCM algorithm will be used to calculate the
    /// shared secret.
    ///
    /// This algorithm must be supported by devices claiming support with Mesh Protocol 1.1.
    ///
    /// - since: Mesh Protocol 1.1.
    case BTM_ECDH_P256_HMAC_SHA256_AES_CCM
    
    var length: Int {
        switch self {
        case .fipsP256EllipticCurve,
             .BTM_ECDH_P256_CMAC_AES128_AES_CCM:
            return 128
        case .BTM_ECDH_P256_HMAC_SHA256_AES_CCM:
            return 256
        }
    }
}

extension Algorithm: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .fipsP256EllipticCurve,
             .BTM_ECDH_P256_CMAC_AES128_AES_CCM:
            return "BTM ECDH P256 CMAC AES128 AES CCM"
        case .BTM_ECDH_P256_HMAC_SHA256_AES_CCM:
            return "BTM ECDH P256 HMAC SHA256 AES CCM"
        }
    }
    
}

/// A set of algorithms supported by the Unprovisioned Device.
public struct Algorithms: OptionSet {
    public let rawValue: UInt16
    
    /// BTM_ECDH_P256_CMAC_AES128_AES_CCM algorithm is supported.
    @available(*, deprecated, renamed: "BTM_ECDH_P256_CMAC_AES128_AES_CCM")
    public static let fipsP256EllipticCurve = Algorithms(rawValue: 1 << 0)
    /// BTM_ECDH_P256_CMAC_AES128_AES_CCM algorithm is supported.
    public static let BTM_ECDH_P256_CMAC_AES128_AES_CCM = Algorithms(rawValue: 1 << 0)
    /// BTM_ECDH_P256_HMAC_SHA256_AES_CCM algorithm is supported.
    public static let BTM_ECDH_P256_HMAC_SHA256_AES_CCM = Algorithms(rawValue: 1 << 1)
    
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    
    /// Returns the strongest provisioning algorithm supported by the device.
    public var strongest: Algorithm {
        if contains(.BTM_ECDH_P256_HMAC_SHA256_AES_CCM) {
            return .BTM_ECDH_P256_HMAC_SHA256_AES_CCM
        }
        return .BTM_ECDH_P256_CMAC_AES128_AES_CCM
    }
}

extension Algorithms: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        if rawValue == 0 {
            return "None"
        }
        return [
            (.BTM_ECDH_P256_CMAC_AES128_AES_CCM, "BTM ECDH P256 CMAC AES128 AES CCM"),
            (.BTM_ECDH_P256_HMAC_SHA256_AES_CCM, "BTM ECDH P256 HMAC SHA256 AES CCM")
            ]
            .compactMap { (option, name) in contains(option) ? name : nil }
            .joined(separator: ", ")
    }
    
}
