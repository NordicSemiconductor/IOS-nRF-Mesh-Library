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
    
    var pdu: ProvisioningPdu {
        switch self {
        case .invite(attentionTimer: let timer):
            var data = ProvisioningPdu(pdu: .invite)
            return data.with(timer)
        }
    }
    
}

extension ProvisioningRequest: CustomDebugStringConvertible {
    
    var debugDescription: String {
        switch self {
        case .invite(attentionTimer: let timer):
            return "Provisioning Invite (attention timer: \(timer) sec)"
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
