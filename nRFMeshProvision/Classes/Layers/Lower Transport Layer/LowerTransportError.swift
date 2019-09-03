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
}

public extension LowerTransportError {
    
    var localizedDescription: String {
        switch self {
        case .timeout: return "Timeout"
        case .busy:    return "Node busy"
        }
    }

}
