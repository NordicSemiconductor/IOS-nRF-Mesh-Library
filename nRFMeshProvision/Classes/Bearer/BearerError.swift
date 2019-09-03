//
//  BearerError.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

public enum BearerError: Error {
    /// Thrown when the Central Manager is not in ON state.
    case centralManagerNotPoweredOn
    /// Thrown when the given PDU type is not supported
    /// by the Bearer.
    case pduTypeNotSupported
    /// Thrown when the Bearer is not ready to send data.
    case bearerClosed
}

public extension BearerError {
    
    var localizedDescription: String {
        switch self {
        case .centralManagerNotPoweredOn: return "Central Manager not powered on"
        case .pduTypeNotSupported:        return "PDU type not supported"
        case .bearerClosed:               return "The bearer is closed"
        }
    }
    
}
