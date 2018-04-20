//
//  AccessMessageParser.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 04/04/2018.
//

import Foundation

public struct AccessMessageParser {
    
    public func parseData(_ someData: Data, withOpcode anOpcode: Data, sourceAddress aSourceAddress: Data) -> Any? {
        switch anOpcode {
        case Data([0x02]):
            return CompositionStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
        case Data([0x80, 0x03]):
            return AppKeyStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
        case Data([0x80, 0x3E]):
            return ModelAppBindStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
        case Data([0x80, 0x19]):
            return ModelPublicationStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
        default:
            return nil
        }
    }
}
