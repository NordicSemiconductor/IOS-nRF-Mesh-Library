//
//  MeshState.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/03/2018.
//

import Foundation

public class MeshState: NSObject, Codable {
    public var name: String
    public var provisionedNodes: [MeshNodeEntry]
    public var netKey          : Data
    public var keyIndex        : Data
    public var IVIndex         : Data
    public var globalTTL       : Data
    public var unicastAddress  : Data
    public var flags           : Data
    public var appKeys         : [[String: Data]]
    
    public func deviceKeyForUnicast(_ aUnicastAddress: Data) -> Data? {
        for aNode in provisionedNodes {
            if aNode.nodeUnicast == aUnicastAddress {
                return aNode.deviceKey
            }
        }
        return nil
    }

    public init(withNodeList aNodeList: [MeshNodeEntry], netKey aNetKey: Data, keyIndex aKeyIndex: Data, IVIndex anIVIndex: Data, globalTTL aTTL: UInt8, unicastAddress aUnicastAddress: Data, flags someFlags: Data, appKeys someKeys: [[String: Data]], andName aName: String) {
        provisionedNodes    = aNodeList
        netKey              = aNetKey
        keyIndex            = aKeyIndex
        IVIndex             = anIVIndex
        globalTTL           = Data([aTTL])
        unicastAddress      = aUnicastAddress
        flags               = someFlags
        name                = aName
        appKeys             = someKeys
    }

}
