//
//  LogEntry.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 18/01/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation

public struct LogEntry {
    let message: String
    let timestamp: Date

    init(withMessage aMessage: String, andTimestamp aTimestamp: Date) {
        message     = aMessage
        timestamp   = aTimestamp
    }
}
