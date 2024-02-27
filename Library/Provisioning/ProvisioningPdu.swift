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

/// The Provisioning Pdu.
internal typealias ProvisioningPdu = Data

/// Provisioning PDU Type.
internal enum ProvisioningPduType: UInt8 {
    /// A Provisioner sends a Provisioning Invite PDU to indicate to the intended
    /// Provisionee that the provisioning process is starting.
    case invite        = 0
    /// The Provisionee sends a Provisioning Capabilities PDU to indicate its
    /// supported provisioning capabilities to a Provisioner.
    case capabilities  = 1
    /// A Provisioner sends a Provisioning Start PDU to indicate the method it
    /// has selected from the options in the Provisioning Capabilities PDU.
    case start         = 2
    /// The Provisioner sends a Provisioning Public Key PDU to deliver the
    /// public key to be used in the ECDH calculations.
    case publicKey     = 3
    /// The Provisionee sends a Provisioning Input Complete PDU when the user
    /// completes the input operation.
    case inputComplete = 4
    /// The Provisioner or the Provisionee sends a Provisioning Confirmation PDU
    /// to its peer to confirm the values exchanged so far, including the
    /// OOB Authentication value and the random number that has yet to be exchanged.
    case confirmation  = 5
    /// The Provisioner or the Provisionee sends a Provisioning Random PDU to
    /// enable its peer device to validate the confirmation.
    case random        = 6
    /// The Provisioner sends a Provisioning Data PDU to deliver provisioning
    /// data to a Provisionee.
    case data          = 7
    /// The Provisionee sends a Provisioning Complete PDU to indicate that it
    /// has successfully received and processed the provisioning data.
    case complete      = 8
    /// The Provisionee sends a Provisioning Failed PDU if it fails to process
    /// a received provisioning protocol PDU.
    case failed        = 9
}

/// Provisioning requests are sent by the Provisioner to an unprovisioned device.
public enum ProvisioningRequest {
    /// A Provisioner sends a Provisioning Invite PDU to indicate to the intended
    /// Provisionee that the provisioning process is starting.
    case invite(attentionTimer: UInt8)
    /// A Provisioner sends a Provisioning Start PDU to indicate the method it
    /// has selected from the options in the Provisioning Capabilities PDU.
    case start(algorithm: Algorithm, publicKey: PublicKeyMethod, authenticationMethod: AuthenticationMethod)
    /// The Provisioner sends a Provisioning Public Key PDU to deliver the public
    /// key to be used in the ECDH calculations.
    case publicKey(_ key: Data)
    /// The Provisioner or the Provisionee sends a Provisioning Confirmation PDU
    /// to its peer to confirm the values exchanged so far, including the
    /// OOB Authentication value and the random number that has yet to be exchanged.
    case confirmation(_ data: Data)
    /// The Provisioner or the Provisionee sends a Provisioning Random PDU to
    /// enable its peer device to validate the confirmation.
    case random(_ data: Data)
    /// The Provisioner sends a Provisioning Data PDU to deliver provisioning data
    /// to a Provisionee.
    case data(_ encryptedDataWithMic: Data)
    
    init(from pdu: ProvisioningPdu) throws {
        guard let pduType = pdu.type, pdu.isValid else {
            throw ProvisioningError.invalidPdu
        }
        switch pduType {
        case .invite:
            self = .invite(attentionTimer: pdu[1])
        case .start:
            guard let algorithm = Algorithm(from: pdu),
                  let publicKey = PublicKeyMethod(from: pdu),
                  let authenticationMethod = AuthenticationMethod(from: pdu) else {
                throw ProvisioningError.invalidPdu
            }
            self = .start(algorithm: algorithm, publicKey: publicKey, authenticationMethod: authenticationMethod)
        case .publicKey:
            self = .publicKey(pdu.suffix(from: 1))
        case .confirmation:
            self = .confirmation(pdu.suffix(from: 1))
        case .random:
            self = .random(pdu.suffix(from: 1))
        case .data:
            self = .data(pdu.suffix(from: 1))
        default:
            throw ProvisioningError.invalidPdu
        }
    }
    
    var pdu: ProvisioningPdu {
        switch self {
        case let .invite(attentionTimer: timer):
            return ProvisioningPdu(pdu: .invite) + timer
        case let .start(algorithm: algorithm, publicKey: publicKey, authenticationMethod: method):
            return ProvisioningPdu(pdu: .start) + algorithm.value + publicKey.value + method.value
        case let .publicKey(key):
            return ProvisioningPdu(pdu: .publicKey) + key
        case let .confirmation(confirmation):
            return ProvisioningPdu(pdu: .confirmation) + confirmation
        case let .random(random):
            return ProvisioningPdu(pdu: .random) + random
        case let .data(encryptedDataWithMic):
            return ProvisioningPdu(pdu: .data) + encryptedDataWithMic
        }
    }
    
}

/// Provisioning responses are sent by the Provisionee to the Provisioner
/// as a response to ``ProvisioningRequest``.
public enum ProvisioningResponse {
    /// The Provisionee sends a Provisioning Capabilities PDU to indicate its
    /// supported provisioning capabilities to a Provisioner.
    case capabilities(_ capabilities: ProvisioningCapabilities)
    /// The Provisionee sends a Provisioning Input Complete PDU when the user
    /// completes the input operation.
    case inputComplete
    /// The Provisioner sends a Provisioning Public Key PDU to deliver the
    /// public key to be used in the ECDH calculations.
    case publicKey(_ key: Data)
    /// The Provisioner or the Provisionee sends a Provisioning Confirmation PDU
    /// to its peer to confirm the values exchanged so far, including the
    /// OOB Authentication value and the random number that has yet to be exchanged.
    case confirmation(_ data: Data)
    /// The Provisioner or the Provisionee sends a Provisioning Random PDU to
    /// enable its peer device to validate the confirmation.
    case random(_ data: Data)
    /// The Provisionee sends a Provisioning Complete PDU to indicate that it
    /// has successfully received and processed the provisioning data.
    case complete
    /// The Provisionee sends a Provisioning Failed PDU if it fails to process
    /// a received provisioning protocol PDU.
    case failed(_ error: RemoteProvisioningError)
    
    init(from pdu: ProvisioningPdu) throws {
        guard let pduType = pdu.type, pdu.isValid else {
            throw ProvisioningError.invalidPdu
        }
        switch pduType {
        case .capabilities:
            guard let capabilities = ProvisioningCapabilities(from: pdu) else {
                throw ProvisioningError.invalidPdu
            }
            self = .capabilities(capabilities)
        case .inputComplete:
            self = .inputComplete
        case .publicKey:
            self = .publicKey(pdu.suffix(from: 1))
        case .confirmation:
            self = .confirmation(pdu.suffix(from: 1))
        case .random:
            self = .random(pdu.suffix(from: 1))
        case .complete:
            self = .complete
        case .failed:
            guard let error = RemoteProvisioningError(rawValue: pdu[1]) else {
                throw ProvisioningError.invalidPdu
            }
            self = .failed(error)
        default:
            throw ProvisioningError.invalidPdu
        }
    }
    
    var pdu: ProvisioningPdu {
        switch self {
        case let .capabilities(capabilities):
            return ProvisioningPdu(pdu: .capabilities) + capabilities.value
        case .inputComplete:
            return ProvisioningPdu(pdu: .inputComplete)
        case let .publicKey(key):
            return ProvisioningPdu(pdu: .publicKey) + key
        case let .confirmation(confirmation):
            return ProvisioningPdu(pdu: .confirmation) + confirmation
        case let .random(random):
            return ProvisioningPdu(pdu: .random) + random
        case .complete:
            return ProvisioningPdu(pdu: .complete)
        case let .failed(error):
            return ProvisioningPdu(pdu: .failed) + error.rawValue
        }
    }
}

// MARK: - String conversion

extension ProvisioningPduType: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .invite:        return "Provisioning Invite"
        case .capabilities:  return "Provisioning Capabilities"
        case .start:         return "Provisioning Start"
        case .publicKey:     return "Provisioning Public Key"
        case .inputComplete: return "Provisioning Input Complete"
        case .confirmation:  return "Provisioning Confirmation"
        case .random:        return "Provisioning Random"
        case .data:          return "Provisioning Data"
        case .complete:      return "Provisioning Complete"
        case .failed:        return "Provisioning Failed"
        }
    }
}

extension ProvisioningRequest: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case let .invite(attentionTimer: timer):
            return "Provisioning Invite (attention timer: \(timer) sec)"
        case let .start(algorithm: algorithm, publicKey: publicKey, authenticationMethod: authenticationMethod):
            return "Provisioning Start (algorithm: \(algorithm), public key: \(publicKey), authentication method: \(authenticationMethod))"
        case let .publicKey(key):
            return "Provisioner Public Key (0x\(key.hex))"
        case let .confirmation(data):
            return "Provisioner Confirmation (0x\(data.hex))"
        case let .random(data):
            return "Provisioner Random (0x\(data.hex))"
        case let .data(data):
            return "Encrypted Provisioning Data (0x\(data.hex))"
        }
    }

}

extension ProvisioningResponse: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case let  .capabilities(capabilities):
            return "Device Capabilities: \(capabilities)"
        case .inputComplete:
            return "Input Complete"
        case let .publicKey(key):
            return "Device Public Key (0x\(key.hex))"
        case let .confirmation(data):
            return "Device Confirmation (0x\(data.hex))"
        case let .random(data):
            return "Device Random (0x\(data.hex))"
        case .complete:
            return "Complete"
        case let .failed(error):
            return "Error: \(error)"
        }
    }
    
}

// MARK: - Encoding and decoding helpers

private extension ProvisioningPdu {
    
    init(pdu: ProvisioningPduType) {
        self = Data([pdu.rawValue])
    }
    
    /// Returns the PDU type from the Provisioning PDU, or `nil` if the PDU is
    /// empty, or the type is not supported.
    var type: ProvisioningPduType? {
        guard count > 0, let pduType = ProvisioningPduType(rawValue: self[0]) else { return nil }
        return pduType
    }
    
    /// Checks whether the PDU is valid and supported.
    ///
    /// Validation is performed only based no length.
    var isValid: Bool {
        switch type {
        case .none: return false
        case .invite, .failed:
            guard count == 1 +  1 else { return false }
        case .capabilities:
            guard count == 1 + 11 else { return false }
        case .start:
            guard count == 1 +  5 else { return false }
        case .publicKey:
            guard count == 1 + 32 + 32 else { return false }
        case .inputComplete, .complete:
            guard count == 1 +  0 else { return false }
        case .confirmation, .random:
            guard count == 1 + 16 ||
                  count == 1 + 32 else { return false }
        case .data:
            guard count == 1 + 25 + 8 else { return false }
        }
        return true
    }
    
}

private extension Algorithm {
    
    init?(from pdu: ProvisioningPdu) {
        switch pdu[1] {
        case 0x00: self = .BTM_ECDH_P256_CMAC_AES128_AES_CCM
        case 0x01: self = .BTM_ECDH_P256_HMAC_SHA256_AES_CCM
        default: return nil
        }
    }
    
    var value: UInt8 {
        switch self {
        case .fipsP256EllipticCurve,
             .BTM_ECDH_P256_CMAC_AES128_AES_CCM:
            return 0x00
        case .BTM_ECDH_P256_HMAC_SHA256_AES_CCM:
            return 0x01
        }
    }
    
}

private extension PublicKeyMethod {
    
    init?(from pdu: ProvisioningPdu) {
        switch pdu[2] {
        case 0x00: self = .noOobPublicKey
        case 0x01: self = .oobPublicKey
        default: return nil
        }
    }
    
    var value: UInt8 {
        switch self {
        case .noOobPublicKey: return 0x00
        case .oobPublicKey:   return 0x01
        }
    }
}

private extension AuthenticationMethod {
    
    init?(from pdu: ProvisioningPdu) {
        switch pdu[3] {
        case 0x00: self = .noOob
        case 0x01: self = .staticOob
        case 0x02:
            guard let outputAction = OutputAction(rawValue: pdu[4]),
                  pdu[5] >= 1 && pdu[5] <= 8 else { return nil }
            self = .outputOob(action: outputAction, size: pdu[5])
        case 0x03:
            guard let inputAction = InputAction(rawValue: pdu[4]),
                  pdu[5] >= 1 && pdu[5] <= 8 else { return nil }
            self = .inputOob(action: inputAction, size: pdu[5])
        default: return nil
        }
    }
    
    var value: Data {
        switch self {
        case .noOob:
            return Data([0, 0, 0])
        case .staticOob:
            return Data([1, 0, 0])
        case let .outputOob(action: action, size: size):
            return Data([2, action.rawValue, size])
        case let .inputOob(action: action, size: size):
            return Data([3, action.rawValue, size])
        }
    }
    
}

private extension ProvisioningCapabilities {
    
    init?(from pdu: ProvisioningPdu) {
        numberOfElements = pdu.read(fromOffset: 1)
        algorithms       = Algorithms(data: pdu, offset: 2)
        publicKeyType    = PublicKeyType(data: pdu, offset: 4)
        oobType          = OobType(data: pdu, offset: 5)
        outputOobSize    = pdu.read(fromOffset: 6)
        outputOobActions = OutputOobActions(data: pdu, offset: 7)
        inputOobSize     = pdu.read(fromOffset: 9)
        inputOobActions  = InputOobActions(data: pdu, offset: 10)
    }
    
    var value: Data {
        return Data([numberOfElements])
            + algorithms.rawValue.bigEndian
            + publicKeyType.rawValue
            + oobType.rawValue
            + outputOobSize
            + outputOobActions.rawValue.bigEndian
            + inputOobSize
            + inputOobActions.rawValue.bigEndian
    }
    
}
