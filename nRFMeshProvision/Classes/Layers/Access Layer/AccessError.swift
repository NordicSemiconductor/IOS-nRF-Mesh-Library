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
    /// Thrown when trying to send a message using an Element
    /// that does not belong to the local Provisioner's Node.
    case invalidElement
    /// Throwm when the given TTL is not valid. Valid TTL must
    /// be 0 or in range 2...127.
    case invalidTtl
    /// Thrown when the destination Address is not known and the
    /// library cannot determine the Network Key to use.
    case invalidDestination
    /// Thrown when trying to send a message from a Model that
    /// does not have any Application Key bound to it.
    case modelNotBoundToAppKey
    /// Error thrown when the Provisioner is trying to delete
    /// the last Network Key from the Node.
    case cannotDelete
    /// Thrown, when the acknowledgment has not been received until
    /// the time run out.
    case timeout
}

extension AccessError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .invalidSource:         return NSLocalizedString("Local Provisioner does not have Unicast Address specified.", comment: "access")
        case .invalidElement:        return NSLocalizedString("Element does not belong to the local Node.", comment: "access")
        case .invalidTtl:            return NSLocalizedString("Invalid TTL", comment: "access")
        case .invalidDestination:    return NSLocalizedString("The destination address is unknown.", comment: "access")
        case .modelNotBoundToAppKey: return NSLocalizedString("No Application Key bound to the given Model.", comment: "access")
        case .cannotDelete:          return NSLocalizedString("Cannot delete the last Network Key.", comment: "access")
        case .timeout:               return NSLocalizedString("Request timed out.", comment: "access")
        }
    }
    
}
