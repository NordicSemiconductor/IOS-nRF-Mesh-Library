//
//  InputOutOfBoundActions.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 20/12/2017.
//

import Foundation

public enum InputOutOfBoundActions: UInt16 {
    case noInput            = 0x00
    case push               = 0x01
    case twist              = 0x02
    case inputNumber        = 0x04
    case inputAlphaNumeric  = 0x08
    
    public func toByteValue() -> UInt8? {
        switch self {
        case .noInput:
            return nil
        case .push:
            return 0
        case .twist:
            return 1
        case .inputNumber:
            return 2
        case .inputAlphaNumeric:
            return 3
        }
    }
    
    public static func allValues() -> [InputOutOfBoundActions] {
        return [
            .push,
            .twist,
            .inputNumber,
            .inputAlphaNumeric
        ]
    }
    
    public static func calculateInputActionsFromBitmask(aBitMask: UInt16) -> [InputOutOfBoundActions] {
        var supportedActions = [InputOutOfBoundActions]()
        for anAction in InputOutOfBoundActions.allValues() {
            if  aBitMask & anAction.rawValue == anAction.rawValue {
                supportedActions.append(anAction)
            }
        }
        return supportedActions
    }

    public func description() -> String {
        switch self {
        case .noInput:
            return "No input"
        case .push:
            return "Push"
        case .twist:
            return "Twist"
        case .inputNumber:
            return "Input number"
        case .inputAlphaNumeric:
            return "Input alphanumeric"
        }
    }
}
