//
//  PublishPeriodResolution.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 03/08/2018.
//

import Foundation

public enum PublishPeriodResolution: UInt8 {
    case hundredsOfMilliseconds = 0x00
    case seconds                = 0x01
    case tensOfSeconds          = 0x02
    case tensOfMinutes          = 0x03
    
    public var description: String  {
        switch self {
        case .hundredsOfMilliseconds:
            return "100s of Milliseconds"
        case .seconds:
            return "seconds"
        case .tensOfSeconds:
            return "10s of Seconds"
        case .tensOfMinutes:
            return "10s of Minutes"
        }
    }
}
