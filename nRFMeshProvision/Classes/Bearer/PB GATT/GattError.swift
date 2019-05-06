//
//  GattError.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

enum GattError: Error {
    case centralManagerNotPoweredOn
    case deviceNotSupported
}
