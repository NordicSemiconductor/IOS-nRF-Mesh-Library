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

public extension MeshMessageError {
    
    var localizedDescription: String {
        switch self {
        case .invalidAddress: return "Invalid address"
        case .invalidPdu:     return "Invalid PDU"
        case .invalidOpCode:  return "Invalid Opcode"
        }
    }
    
}

