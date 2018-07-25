//
//  DiscoveryConfiguratorState.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/02/2018.
//

import CoreBluetooth
import Foundation

class DiscoveryConfiguratorState: NSObject, ConfiguratorStateProtocol {

    // MARK: - Properties
    private var proxyService            : CBService!
    private var dataInCharacteristic    : CBCharacteristic!
    private var dataOutCharacteristic   : CBCharacteristic!
    
    // MARK: - ConfiguratorStateProtocol
    var destinationAddress: Data
    var target          : ProvisionedMeshNodeProtocol
    var stateManager    : MeshStateManager

    required init(withTargetProxyNode aNode: ProvisionedMeshNodeProtocol,
                  destinationAddress aDestinadionAddress: Data,
                  andStateManager aStateManager: MeshStateManager) {
        target = aNode
        destinationAddress = aDestinadionAddress
        stateManager = aStateManager
        super.init()
        target.basePeripheral().delegate = self
    }

    func humanReadableName() -> String {
        return "PB-GATT Proxy Discovery"
    }

    func execute() {
        target.basePeripheral().discoverServices([MeshServiceProxyUUID])
    }
   
    // MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            services.forEach({ (aService) in
                if aService.uuid == MeshServiceProxyUUID {
                    print("Discovered mesh proxy service")
                    proxyService = aService
                    //Discover Data in & Data out characteristics
                    print("Discovering characteristics for provisioning service")
                    peripheral.discoverCharacteristics([MeshCharacteristicProxyDataOutUUID, MeshCharacteristicProxyDataInUUID], for: aService)
                }
       })
        }
   }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            characteristics.forEach({ (aCharacteristic) in
                if aCharacteristic.uuid == MeshCharacteristicProxyDataInUUID {
                    print("Discovered data in charcateristic")
                    dataInCharacteristic = aCharacteristic
                } else if aCharacteristic.uuid == MeshCharacteristicProxyDataOutUUID {
                    print("Discovered data out characteristic")
                    dataOutCharacteristic = aCharacteristic
                    peripheral.setNotifyValue(true, for: dataOutCharacteristic)
                }
           
                if dataInCharacteristic != nil && dataOutCharacteristic != nil && dataOutCharacteristic.isNotifying {
                    print("Discovery completed")
                    target.completedDiscovery(withProxyService: proxyService,
                                              dataInCharacteristic: dataInCharacteristic,
                                              andDataOutCharacteristic: dataOutCharacteristic)
                }
       })
        }
   }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        //NOOP
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == dataOutCharacteristic {
            if dataInCharacteristic != nil {
                target.completedDiscovery(withProxyService: proxyService,
                                          dataInCharacteristic: dataInCharacteristic,
                                          andDataOutCharacteristic: dataOutCharacteristic)
            }
    }
   }
}
