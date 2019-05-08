//
//  BearerError.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

public enum BearerError: Error {
    case centralManagerNotPoweredOn
}

public enum GattBearerError: Error {
    case deviceNotSupported
}
