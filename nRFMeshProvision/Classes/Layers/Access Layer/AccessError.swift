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
    /// Thrown when the destination Address is not known and the
    /// library cannot determine the Network Key to use.
    case invalidDestination
    /// Error thrown when the Provisioner is trying to remove
    /// the last Network Key from the Node.
    case cannotRemove
}

public extension AccessError {
    
    var localizedDescription: String {
        switch self {
        case .invalidSource:      return "Local Provisioner does not have Unicast Address specified"
        case .invalidDestination: return "The destination address is unknown"
        case .cannotRemove:       return "Cannot remove the last Network Key"
        }
    }
    
}
