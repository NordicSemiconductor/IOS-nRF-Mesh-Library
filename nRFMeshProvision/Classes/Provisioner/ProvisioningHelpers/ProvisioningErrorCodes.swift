//
//  ProvisioningErrorCodes.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 19/01/2018.
//

import Foundation

public enum ProvisioningErrorCodes: UInt8 {
    case invalidPDU             = 0x01
    case invalidFormat          = 0x02
    case unexpectedPDU          = 0x03
    case confirmationFailed     = 0x04
    case outOfResources         = 0x05
    case decryptionFailed       = 0x06
    case unexpectedError        = 0x07
    case cannotAssignAddress    = 0x08
    
    func description() -> String {
        switch self {
            case .invalidPDU:
                return "Invalid PDU"
            case .invalidFormat:
                return "Invalid format"
            case .unexpectedPDU:
                return "Unexpected PDU"
            case .confirmationFailed:
                return "Confirmation failed"
            case .outOfResources:
                return "Out of resources"
            case .decryptionFailed:
                return "Dercryption failed"
            case .unexpectedError:
                return "Unexpected error"
            case .cannotAssignAddress:
                return "Cannot assign address"
        }
   }
}
