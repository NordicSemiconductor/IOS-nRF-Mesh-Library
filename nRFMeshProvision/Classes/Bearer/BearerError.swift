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

extension BearerError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .centralManagerNotPoweredOn: return NSLocalizedString("Central Manager not powered on.", comment: "")
        case .pduTypeNotSupported:        return NSLocalizedString("PDU type not supported.", comment: "")
        case .bearerClosed:               return NSLocalizedString("The bearer is closed.", comment: "")
        }
    }
    
}
