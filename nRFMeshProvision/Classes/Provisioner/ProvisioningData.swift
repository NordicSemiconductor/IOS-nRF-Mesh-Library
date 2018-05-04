//
//  ProvisioningData.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 17/01/2018.
//

import Foundation

public struct ProvisioningData {
    
    public init(netKey aNetKey: Data, keyIndex aKeyIndex: Data, flags someFlags: Data, ivIndex anIVIndex: Data, friendlyName aFriendlyName: String, unicastAddress anAddress: Data) {
        friendlyName    = aFriendlyName
        netKey          = aNetKey
        keyIndex        = aKeyIndex
        flags           = someFlags
        ivIndex         = anIVIndex
        unicastAddr     = anAddress
    }

    public let netKey      : Data
    public let keyIndex    : Data
    public let flags       : Data
    public let ivIndex     : Data
    public let unicastAddr : Data
    public let friendlyName: String
}
