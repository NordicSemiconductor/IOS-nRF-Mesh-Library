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

internal typealias ProvisioningPdu = Data

internal enum ProvisioningPduType: UInt8 {
    case invite        = 0
    case capabilities  = 1
    case start         = 2
    case publicKey     = 3
    case inputComplete = 4
    case confirmation  = 5
    case random        = 6
    case data          = 7
    case complete      = 8
    case failed        = 9
    
    var type: UInt8 {
        return rawValue
    }
}

internal enum ProvisioningRequest {
    case invite(attentionTimer: UInt8)
    case start(algorithm: Algorithm, publicKey: PublicKey, authenticationMethod: AuthenticationMethod)
    case publicKey(_ key: Data)
    case confirmation(_ data: Data)
    case random(_ data: Data)
    case data(_ encryptedDataWithMic: Data)
    
    var pdu: ProvisioningPdu {
        switch self {
        case let .invite(attentionTimer: timer):
            var data = ProvisioningPdu(pdu: .invite)
            return data.with(timer)
        case let .start(algorithm: algorithm, publicKey: publicKey, authenticationMethod: method):
            var data = ProvisioningPdu(pdu: .start)
            data += algorithm.value
            data += publicKey.value
            data += method.value
            return data
        case let .publicKey(key):
            var data = ProvisioningPdu(pdu: .publicKey)
            data += key
            return data
        case let .confirmation(confirmation):
            var data = ProvisioningPdu(pdu: .confirmation)
            data += confirmation
            return data
        case let .random(random):
            var data = ProvisioningPdu(pdu: .random)
            data += random
            return data
        case let .data(encryptedDataWithMic):
            var data = ProvisioningPdu(pdu: .data)
            data += encryptedDataWithMic
            return data
        }
    }
    
}

internal struct ProvisioningResponse {
    let type: ProvisioningPduType
    let capabilities: ProvisioningCapabilities?
    let publicKey: Data?
    let confirmation: Data?
    let random: Data?
    let error: RemoteProvisioningError?
    
    init?(_ data: Data) {
        guard data.count > 0, let pduType = ProvisioningPduType(rawValue: data[0]) else {
            return nil
        }
        
        self.type = pduType
        
        switch pduType {
        case .capabilities:
            capabilities = ProvisioningCapabilities(data)
            publicKey = nil
            confirmation = nil
            random = nil
            error = nil
        case .publicKey:
            publicKey = data.subdata(in: 1..<data.count)
            capabilities = nil
            confirmation = nil
            random = nil
            error = nil
        case .inputComplete, .complete:
            publicKey = nil
            capabilities = nil
            confirmation = nil
            random = nil
            error = nil
        case .confirmation:
            publicKey = nil
            capabilities = nil
            confirmation = data.subdata(in: 1..<data.count)
            random = nil
            error = nil
        case .random:
            publicKey = nil
            capabilities = nil
            confirmation = nil
            random = data.subdata(in: 1..<data.count)
            error = nil
        case .failed:
            guard data.count == 2, let status = RemoteProvisioningError(rawValue: data[1]) else {
                return nil
            }
            publicKey = nil
            capabilities = nil
            confirmation = nil
            random = nil
            error = status
        default:
            return nil
        }
    }
    
    func isValid(forAlgorithm algorithm: Algorithm?) -> Bool {
        switch type {
        case .capabilities:
            return capabilities != nil
        case .publicKey:
            return publicKey != nil
        case .inputComplete, .complete:
            return true
        case .confirmation:
            guard let algorithm = algorithm else { return false }
            let sizeInBytes = algorithm.length >> 3
            return confirmation != nil && confirmation!.count == sizeInBytes
        case .random:
            guard let algorithm = algorithm else { return false }
            let sizeInBytes = algorithm.length >> 3
            return random != nil && random!.count == sizeInBytes
        case .failed:
            return error != nil
        default:
            return false
        }
    }
}

extension ProvisioningPduType: CustomDebugStringConvertible {
    
    var debugDescription: String {
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
    
    var debugDescription: String {
        switch self {
        case let .invite(attentionTimer: timer):
            return "Provisioning Invite (attention timer: \(timer) sec)"
        case let .start(algorithm: algorithm, publicKey: publicKey, authenticationMethod: authenticationMethod):
            return "Provisioning Start (algorithm: \(algorithm), public Key: \(publicKey), authentication Method: \(authenticationMethod))"
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
    
    var debugDescription: String {
        guard isValid(forAlgorithm: .BTM_ECDH_P256_CMAC_AES128_AES_CCM) ||
              isValid(forAlgorithm: .BTM_ECDH_P256_HMAC_SHA256_AES_CCM) else {
            return "Invalid response of type: \(type)"
        }
        switch type {
        case .capabilities: return "Device Capabilities: \(capabilities!)"
        case .publicKey:    return "Device Public Key (0x\(publicKey!.hex))"
        case .confirmation: return "Device Confirmation (0x\(confirmation!.hex))"
        case .random:       return "Device Random (0x\(random!.hex))"
        case .failed:       return "Error: \(error!)"
        default:            return "\(type)"
        }
    }
    
}

private extension Data {
    
    init(pdu: ProvisioningPduType) {
        self = Data([pdu.type])
    }
    
    mutating func with(_ parameter: UInt8) -> Data {
        self.append(parameter)
        return self
    }
    
    mutating func with(_ parameter: UInt16) -> Data {
        self.append(parameter.data)
        return self
    }
    
}
