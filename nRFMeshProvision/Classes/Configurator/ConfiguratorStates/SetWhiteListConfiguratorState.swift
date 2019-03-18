//
//  SetWhiteListConfiguratorState.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/02/2018.
//

import CoreBluetooth
import Foundation

class SetWhiteListConfiguratorState: NSObject, ConfiguratorStateProtocol {

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
        return "Set filter to white list"
    }

    func execute() {
        let message = SetFilterTypeMessage(withFilterType: MeshFilterTypes.whiteList)
        //Sent to unassigned address
        let payloads = message.assemblePayload(withMeshState: stateManager.state(), toAddress: destinationAddress)
        
        for aPayload in payloads! {
            var data = Data([0x02])
            data.append(aPayload)
            target.basePeripheral().writeValue(data, for: dataInCharacteristic, type: .withoutResponse)
        }
   }
    
    // MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        //NOOP
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        //NOOP
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Characteristic value updated: \(characteristic.value!.hexString())")
        let value = characteristic.value!
        if value[0] == 0x01 {
            print("Ignoring secure beacon")
            return
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("Characteristic notification state changed")
    }
}
