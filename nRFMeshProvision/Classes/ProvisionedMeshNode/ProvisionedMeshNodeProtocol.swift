//
//  ProvisionedMeshNodeProtocol.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/02/2018.
//

import Foundation
import CoreBluetooth

protocol ProvisionedMeshNodeProtocol {

    // MARK: - Properties
    var logDelegate         : ProvisionedMeshNodeLoggingDelegate? {set get}
    var delegate            : ProvisionedMeshNodeDelegate? {set get}

    // MARK: - Accessors
    func basePeripheral() -> CBPeripheral

    func discoveredServicesAndCharacteristics() -> (
        proxyService            : CBService?,
        dataInCharacteristic    : CBCharacteristic?,
        dataOutCharacteristic   : CBCharacteristic?
    )

    // MARK: - Property updates
    func configurationCompleted()
    func completedDiscovery(withProxyService aProxyService: CBService,
                            dataInCharacteristic aDataInCharacteristic: CBCharacteristic,
                            andDataOutCharacteristic aDataOutCharacteristic: CBCharacteristic)

    // MARK: - State related
    func switchToState(_ nextState : ConfiguratorStateProtocol)
    func shouldDisconnect()
}
