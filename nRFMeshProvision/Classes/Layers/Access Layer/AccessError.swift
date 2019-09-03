//
//  AccessError.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 03/09/2019.
//

import Foundation

public enum AccessError: Error {
    /// Error thrown when the local Provisioner does not have
    /// a Unicast Address specified and is not able to send
    /// requested message.
    case invalidSource
}

public extension AccessError {
    
    var localizedDescription: String {
        switch self {
        case .invalidSource: return "Local Provisioner does not have Unicast Address specified"
        }
    }
    
}
