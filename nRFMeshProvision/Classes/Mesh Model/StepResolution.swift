//
//  StepResolution.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 22/08/2019.
//

import Foundation

public enum StepResolution: UInt8 {
    case hundredsOfMilliseconds = 0b00
    case seconds                = 0b01
    case tensOfSeconds          = 0b10
    case tensOfMinutes          = 0b11
    
    func toPeriod(steps: UInt8) -> Int {
        switch self {
        case .hundredsOfMilliseconds:
            return Int(steps) * 100
        case .seconds:
            return Int(steps) * 1000
        case .tensOfSeconds:
            return Int(steps) * 10000
        case .tensOfMinutes:
            return Int(steps) * 600000
        }
    }
}

extension StepResolution: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .hundredsOfMilliseconds:
            return "100 milliseconds"
        case .seconds:
            return "1 second"
        case .tensOfSeconds:
            return "10 seconds"
        case .tensOfMinutes:
            return "10 minutes"
        }
    }
    
}
