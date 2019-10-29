//
//  Security.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 25/03/2019.
//

import Foundation

/// The type representing Security level for the subnet on which a
/// node has been originally provisioned.
public enum Security: String, Codable {
    case low    = "low"
    case high   = "high"
}

extension Security: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .low:  return "Low"
        case .high: return "High"
        }
    }
    
}
