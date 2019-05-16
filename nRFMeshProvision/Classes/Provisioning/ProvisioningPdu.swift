//
//  ProvisioningPduType.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 07/05/2019.
//

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
    
    var isValid: Bool {
        switch type {
        case .capabilities:
            return capabilities != nil
        case .publicKey:
            return publicKey != nil
        case .inputComplete, .complete:
            return true
        case .confirmation:
            return confirmation != nil && confirmation!.count == 16
        case .random:
            return random != nil && random!.count == 16
        case .failed:
            return error != nil
        default:
            return false
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
            return "Provisioning Confirmation (0x\(data.hex)"
        case let .random(data):
            return "Provisioning Random (0x\(data.hex)"
        case let .data(data):
            return "Encrypted Provisioning Data (0x\(data.hex))"
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
