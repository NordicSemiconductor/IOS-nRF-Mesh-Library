//
//  InputOutOfBoundActions.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 20/12/2017.
//

import Foundation

enum InputOutOfBoundActions: UInt16 {
    case noInput            = 0x00
    case push               = 0x01
    case twist              = 0x02
    case inputNumber        = 0x04
    case inputAlphaNumeric  = 0x08
}
