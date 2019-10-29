//
//  MeshMessageError.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 25/05/2019.
//

import Foundation

public enum MeshMessageError: Error {
    case invalidAddress
    case invalidPdu
    case invalidOpCode
}

extension MeshMessageError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .invalidAddress: return NSLocalizedString("Invalid address.", comment: "")
        case .invalidPdu:     return NSLocalizedString("Invalid PDU.", comment: "")
        case .invalidOpCode:  return NSLocalizedString("Invalid Opcode.", comment: "")
        }
    }
    
}

