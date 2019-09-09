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

extension AccessError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .invalidSource:      return NSLocalizedString("Local Provisioner does not have Unicast Address specified.", comment: "")
        case .invalidDestination: return NSLocalizedString("The destination address is unknown.", comment: "")
        case .cannotRemove:       return NSLocalizedString("Cannot remove the last Network Key.", comment: "")
        }
    }
    
}
