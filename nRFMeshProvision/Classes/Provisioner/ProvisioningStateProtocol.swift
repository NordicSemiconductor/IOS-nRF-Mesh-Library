//
//  ProvisioningStateProtocol.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 20/12/2017.
//

import Foundation
import CoreBluetooth

protocol ProvisioningStateProtocol : CBPeripheralDelegate {
    var target: UnprovisionedMeshNodeProtocol { get set }
    init(withTargetNode aNode: UnprovisionedMeshNodeProtocol)
    func execute()
    func humanReadableName() -> String
}
