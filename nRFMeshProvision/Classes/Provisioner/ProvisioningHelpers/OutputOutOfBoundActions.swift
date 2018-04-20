//
//  OutputOutOfBoundActions.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 20/12/2017.
//

import Foundation

enum OutputOutOfBoundActions: UInt16 {
    case noOutput           = 0x0000
    case blink              = 0x0001
    case beep               = 0x0002
    case vibrate            = 0x0004
    case outputNumeric      = 0x0008
    case outputAlphaNumeric = 0x0010
    
    public func toByteValue() -> UInt8? {
        switch self {
        case .blink:
            return 0
        case .beep:
            return 1
        case .vibrate:
            return 2
        case .outputNumeric:
            return 3
        case .outputAlphaNumeric:
            return 4
        default:
            return nil
        }
   }
    
    public func description() -> String {
        switch self {
        case .noOutput:
            return "No output"
        case .blink:
            return "Blink"
        case .beep:
            return "Beep"
        case .vibrate:
            return "Vibrate"
        case .outputNumeric:
            return "Numeric output"
        case .outputAlphaNumeric:
            return "Alphanumeric output"
        }
   }
}
