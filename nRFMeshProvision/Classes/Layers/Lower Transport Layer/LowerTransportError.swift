//
//  LowerTransportError.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 02/08/2019.
//

import Foundation

public enum LowerTransportError: Error {
    /// The segmented message has not been acknowledged before the timeout occurred.
    case timeout
    /// The target device is busy at the moment and could not accept the message.
    case busy
    /// Thrown internally when a possible replay attack was detected.
    /// This error is not propagated to higher levels, the packet is
    /// being discarded.
    case replayAttack
}

extension LowerTransportError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .timeout: return NSLocalizedString("Request timed out.", comment: "lowerTransport")
        case .busy:    return NSLocalizedString("Node is busy. Try later.", comment: "lowerTransport")
        case .replayAttack: return NSLocalizedString("Possible replay attack detected", comment: "lowerTransport")
        }
    }

}
