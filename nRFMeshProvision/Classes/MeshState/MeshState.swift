//
//  MeshState.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/03/2018.
//

import Foundation

public class MeshState: NSObject, Codable {
    public var name: String
    public var nextUnicast      : Data
    public var provisionedNodes : [MeshNodeEntry]
    public var netKey           : Data
    public var keyIndex         : Data
    public var IVIndex          : Data
    public var globalTTL        : Data
    public var unicastAddress   : Data
    public var flags            : Data
    public var appKeys          : [[String: Data]]
    
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
        nextUnicast         = Data([0x00,0x01])
    }

    public func incrementUnicastBy(_ aCount: Int) {
        var unicastData = nextUnicast
        print("Incrementing Unicast: \(nextUnicast.hexString()) by \(aCount)")
        let unicastNumber = (UInt16(unicastData[0]) << 8) | (UInt16(unicastData[1]) & 0x00FF)
        //Increment by the amount of elements added, then add one to get the next free addrses
        let newUnicastNumber = unicastNumber + UInt16(aCount)
        let newUnicastData = Data([UInt8(newUnicastNumber >> 8), UInt8(newUnicastNumber & 0x00FF)])
        nextUnicast = newUnicastData
        print("Next available unicast: \(nextUnicast.hexString())")
    }
}
