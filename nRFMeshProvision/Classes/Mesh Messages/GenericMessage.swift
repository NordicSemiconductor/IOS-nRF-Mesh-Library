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

public extension Array where Element == GenericMessage.Type {
    
    /// A helper method that can create a map of message types required
    /// by the `ModelDelegate` from a list of `GenericMessage`s.
    ///
    /// - returns: A map of message types.
    func toMap() -> [UInt32 : MeshMessage.Type] {
        return (self as [StaticMeshMessage.Type]).toMap()
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
