//
//  GenericMessage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 23/08/2019.
//

import Foundation

public protocol GenericMessage: StaticMeshMessage {
    // No additional fields.
}
public protocol AcknowledgedGenericMessage: GenericMessage, StaticAcknowledgedMeshMessage {
    // No additional fields.
}

public enum GenericMessageStatus: UInt8 {
    case success           = 0x00
    case cannotSetRangeMin = 0x01
    case cannotSetRangeMax = 0x02
}

public protocol GenericStatusMessage: GenericMessage, StatusMessage {
    /// Operation status.
    var status: GenericMessageStatus { get }
}

public extension GenericStatusMessage {
    
    var isSuccess: Bool {
        return status == .success
    }
    
    var message: String {
        return "\(status)"
    }
    
}

extension GenericMessageStatus: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .success:
            return "Success"
        case .cannotSetRangeMin:
            return "Cannot Set Range Min"
        case .cannotSetRangeMax:
            return "Cannot Set Range Max"
        }
    }
    
}
