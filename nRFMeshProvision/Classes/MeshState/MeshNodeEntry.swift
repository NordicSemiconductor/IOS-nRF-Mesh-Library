//
//  MeshNodeEntry.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/03/2018.
//

import Foundation

public class MeshNodeEntry: NSObject, Codable {

    // MARK: - Properties
    public let nodeName                : String
    public let provisionedTimeStamp    : Date
    public let nodeId                  : Data
    public let deviceKey               : Data
    public var appKeys                 : [Data]
    public var nodeUnicast             : Data?
    // MARK: -  Node composition
    public var companyIdentifier       : Data?
    public var productIdentifier       : Data?
    public var productVersion          : Data?
    public var replayProtectionCount   : Data?
    public var featureFlags            : Data?
    public var elements                : [CompositionElement]?

    // MARK: - Initialization
    public init(withName aName: String, provisionDate aProvisioningTimestamp: Date, nodeId anId: Data, andDeviceKey aDeviceKey: Data) {
        nodeName                    = aName
        provisionedTimeStamp        = aProvisioningTimestamp
        nodeId                      = anId
        deviceKey                   = aDeviceKey
        appKeys                     = [Data]()
    }
}
