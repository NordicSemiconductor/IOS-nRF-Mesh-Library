//
//  MeshVendorModelIdentifierStringConverter.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 16/04/2018.
//
import Foundation

public struct MeshVendorModelIdentifierStringConverter {
    let identifierMap: [MeshVendorModelIdentifiers: String]
    
    public init() {
        identifierMap = [
            .nordicSimpleOnOffServer: "Simple OnOff Server",
            .nordicSimpleOnOffClient: "Simple OnOff Client",
        ]
    }
    public func stringValueForIdentifier(_ aModelIdentifier: MeshVendorModelIdentifiers) -> String {
        if let stringValue = identifierMap[aModelIdentifier] {
            return stringValue
        }
        return "Unknown Vendor Identifier"
    }
}
