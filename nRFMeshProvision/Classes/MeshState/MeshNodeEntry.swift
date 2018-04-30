//
//  MeshNodeEntry.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/03/2018.
//

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
    public var vendorIdentifier        : Data?
    public var replayProtectionCount   : Data?
    public var featureFlags            : Data?
    public var elements                : [CompositionElement]?
    public var modelKeyBindings        : [Data: Data]
    public var modelPublishAddresses   : [Data: Data]
    public var modelSubscriptionAddresses: [Data: [Data]]

    // MARK: - Initialization
    public init(withName aName: String, provisionDate aProvisioningTimestamp: Date, nodeId anId: Data, andDeviceKey aDeviceKey: Data) {
        nodeName                    = aName
        provisionedTimeStamp        = aProvisioningTimestamp
        nodeId                      = anId
        deviceKey                   = aDeviceKey
        modelKeyBindings            = [Data: Data]()
        modelPublishAddresses       = [Data: Data]()
        modelSubscriptionAddresses  = [Data: [Data]]()
        appKeys                     = [Data]()
    }
}
