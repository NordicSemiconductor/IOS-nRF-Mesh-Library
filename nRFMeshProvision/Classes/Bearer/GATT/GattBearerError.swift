//
//  GattBearerError.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 09/05/2019.
//

import Foundation

public enum GattBearerError: Error {
    /// The connected device does not have services required
    /// by the Bearer.
    case deviceNotSupported
}
