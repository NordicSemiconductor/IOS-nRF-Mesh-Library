//
//  SleepConfiguratorState.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/04/2018.
//

import CoreBluetooth

class SleepConfiguratorState: NSObject, ConfiguratorStateProtocol {
    
    // MARK: - Properties
    private var proxyService            : CBService!
    private var dataInCharacteristic    : CBCharacteristic!
    private var dataOutCharacteristic   : CBCharacteristic!
    
    // MARK: - ConfiguratorStateProtocol
    var destinationAddress  : Data
    var target              : ProvisionedMeshNodeProtocol
    var stateManager        : MeshStateManager
    
    required init(withTargetProxyNode aNode: ProvisionedMeshNodeProtocol,
                  destinationAddress aDestinationAddress: Data,
                  andStateManager aStateManager: MeshStateManager) {
        target = aNode
        stateManager = aStateManager
        destinationAddress = aDestinationAddress
        super.init()
        target.basePeripheral().delegate = self
        //If services and characteristics are already discovered, set them now
        let discovery           = target.discoveredServicesAndCharacteristics()
        proxyService            = discovery.proxyService
        dataInCharacteristic    = discovery.dataInCharacteristic
        dataOutCharacteristic   = discovery.dataOutCharacteristic
    }
    
    func humanReadableName() -> String {
        return "Sleep"
    }
    
    func execute() {
        print("Sleeping indefinitely")
    }
    
    // MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        //NOOP
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        //NOOP
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        //NOOP
        print("Ignoring incoming data, sleeping...")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("Ignoring notification state changed, sleeping...")
    }
}
