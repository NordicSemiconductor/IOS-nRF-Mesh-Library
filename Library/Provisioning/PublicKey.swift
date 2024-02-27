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

/// The type of Device Public key to be used.
///
/// This enumeration is used to specify the Public Key type during provisioning
/// in ``ProvisioningManager/provision(usingAlgorithm:publicKey:authenticationMethod:)``.
public enum PublicKey {
    /// No OOB Public Key is used.
    case noOobPublicKey
    /// OOB Public Key is used. The key must contain the full value of the Public Key,
    /// depending on the chosen algorithm.
    ///
    /// - parameter key: The Public Key consists of 256-bit X and 256-bit Y of a point Q
    ///                  on P256 curve.
    case oobPublicKey(key: Data)
    
    var method: PublicKeyMethod {
        switch self {
        case .noOobPublicKey:       return .noOobPublicKey
        case .oobPublicKey(key: _): return .oobPublicKey
        }
    }
}

extension PublicKey: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .noOobPublicKey:
            return "No OOB Public Key"
        case .oobPublicKey(key: _):
            return "OOB Public Key"
        }
    }
    
}

/// The type of Device Public key to be used.
///
/// This enumeration is used in ``ProvisioningRequest/start(algorithm:publicKey:authenticationMethod:)``
/// to encode the selected Public Key type.
public enum PublicKeyMethod {
    /// No OOB Public Key is used.
    case noOobPublicKey
    /// OOB Public Key is used. The key must contain the full value of the Public Key,
    /// depending on the chosen algorithm.
    case oobPublicKey
}

extension PublicKeyMethod: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .noOobPublicKey:
            return "No OOB Public Key"
        case .oobPublicKey:
            return "OOB Public Key"
        }
    }
    
}

/// The type of Public Key information.
public struct PublicKeyType: OptionSet {
    public let rawValue: UInt8
    
    /// Public Key OOB Information is available.
    public static let publicKeyOobInformationAvailable = PublicKeyType(rawValue: 1 << 0)
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
}

extension PublicKeyType: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        if rawValue == 0 {
            return "None"
        }
        return [(.publicKeyOobInformationAvailable, "Public Key OOB Information Available")]
            .compactMap { (option, name) in contains(option) ? name : nil }
            .joined(separator: ", ")
    }
    
}
