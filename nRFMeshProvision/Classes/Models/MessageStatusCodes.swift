//
//  MessageStatusCodes.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 13/04/2018.
//

import Foundation

public enum MessageStatusCodes: UInt8 {
    case success                        = 0x00
    case invalidAdderss                 = 0x01
    case invalidModel                   = 0x02
    case invalidAppKeyIndex             = 0x03
    case invalidNetKeyIndex             = 0x04
    case insufficientResources          = 0x05
    case keyIndexAlreadyStored          = 0x06
    case invalidPublishParameters       = 0x07
    case notASubscribedModel            = 0x08
    case storageFailure                 = 0x09
    case featureNotSupported            = 0x0A
    case cannotUpdate                   = 0x0B
    case cannotRemove                   = 0x0C
    case cannotBind                     = 0x0D
    case temporarilyUnableToChangeState = 0x0E
    case cannotSet                      = 0x0F
    case unspecifiedError               = 0x10
    case invalidBinding                 = 0x11
}
