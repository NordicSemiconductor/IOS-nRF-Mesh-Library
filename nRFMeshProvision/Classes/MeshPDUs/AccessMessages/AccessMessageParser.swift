//
//  AccessMessageParser.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 04/04/2018.
//

import Foundation

public struct AccessMessageParser {
    
    public static func parseData(_ someData: Data, withOpcode anOpcode: Data, sourceAddress aSourceAddress: Data) -> Any? {
        // handle vendor messages, which are
        switch anOpcode.count {
        case 1:
            switch anOpcode {
            case Data([0x02]):
                return CompositionStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
            case Data([0x5E]):
                return SceneStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
            default:
                return nil
            }
            
        case 2:
            switch anOpcode {
            //Configuration Messages
            case Data([0x02]):
                return CompositionStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
            
            // Scene messages
            case Data([0x5E]):
                return SceneStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
            case Data([0x80, 0x03]):
                return AppKeyStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
            case Data([0x80, 0x3E]):
                return ModelAppStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
            case Data([0x80, 0x19]):
                return ModelPublicationStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
            case Data([0x80, 0x1F]):
                return ModelSubscriptionStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
            case Data([0x80, 0x0E]):
                return DefaultTTLStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
            case Data([0x80, 0x4A]):
                return NodeResetStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
                
            //Generic Model Messages
            case Data([0x82, 0x04]):
                return GenericOnOffStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
            case Data([0x82, 0x08]):
                return GenericLevelStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
            case Data([0x82, 0x4E]):
                return LightLightnessStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
            case Data([0x82, 0x60]):
                return LightCtlStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
            case Data([0x82, 0x78]):
                return LightHslStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
            case Data([0x82, 0x45]):
                return SceneRegisterStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress)
            default:
                return nil;
            }
            
        case 3:
            return VendorModelStatusMessage(withPayload: someData, andSoruceAddress: aSourceAddress);
            
        default:
            return nil;
        }
            
    }
}
