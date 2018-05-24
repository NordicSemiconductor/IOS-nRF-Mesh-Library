//
//  GenericModelControllerStateProtocol.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 24/05/2018.
//

import Foundation
import CoreBluetooth

protocol GenericModelControllerStateProtocol: CBPeripheralDelegate {
    var stateManager: MeshStateManager { get set }
    var target: ProvisionedMeshNodeProtocol { get set }
    var destinationAddress: Data { get set }
    init(withTargetProxyNode aNode: ProvisionedMeshNodeProtocol,
         destinationAddress aDestinationAddress: Data,
         andStateManager aStateManager: MeshStateManager)
    func execute()
    func humanReadableName() -> String
}
