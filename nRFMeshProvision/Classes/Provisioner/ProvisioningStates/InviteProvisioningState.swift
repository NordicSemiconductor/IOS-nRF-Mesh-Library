//
//  InviteProvisioningState.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 20/12/2017.
//

import Foundation
import CoreBluetooth

class InviteProvisioningState: NSObject, ProvisioningStateProtocol {

    // MARK: - Properties
    private var provisioningService: CBService!
    private var dataInCharacteristic: CBCharacteristic!
    private var dataOutCharacteristic: CBCharacteristic!

    // MARK: - ProvisioningStateProtocol
    var target: UnprovisionedMeshNodeProtocol

    func humanReadableName() -> String {
        return "Invite"
    }

    required init(withTargetNode aNode: UnprovisionedMeshNodeProtocol) {
        target                              = aNode
        super.init()
        target.basePeripheral().delegate    = self
        //If services and characteristics are already discovered, set them now
        let discovery                       = target.discoveredServicesAndCharacteristics()
        provisioningService                 = discovery.provisionService
        dataInCharacteristic                = discovery.dataInCharacteristic
        dataOutCharacteristic               = discovery.dataOutCharacteristic
    }
   
    func execute() {
        let invitePDU = Data(bytes: [0x03, 0x00, 0x00])
        print(invitePDU.hexString())

        // Store generated invite PDU Data, first two bytes are PDU related and are not used further.
        target.generatedProvisioningInviteData(invitePDU.dropFirst().dropFirst())
        target.basePeripheral().writeValue(invitePDU, for: dataInCharacteristic, type: .withoutResponse)
    }
   
    // MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        //NOOP
    }
   
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        //NOOP
    }
   
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            let provisioningMessage = data[0]
            let messageType         = data[1]
            guard provisioningMessage == 0x03 && messageType == 0x01 else {
                print("Unexpected message type received")
                print("Expected: 0301")
                print("Received: \(provisioningMessage)\(messageType)")
                return
            }
            print("Received capabilities provisioning message")
            let elementCount        = Int(data[2])
            let algorithm           = ProvisioningAlgorithm(rawValue: UInt16(data[3] << 0xFF) + UInt16(data[4] & 0x00FF))!
            let pubKeyType          = PublicKeyInformationAvailability(rawValue: data[5])!
            let staticOOBType       = StaticOutOfBoundInformationAvailability(rawValue: data[6])!
            let outputOOBSize       = data[7]
            let outputOOBAction     = OutputOutOfBoundActions(rawValue: UInt16(data[8] << 0xFF) + UInt16(data[9] & 0x00FF))!
            let inputOOBSize        = data[10]
            let inputOOBAction      = InputOutOfBoundActions(rawValue: UInt16(data[11] << 0xFF) + UInt16(data[12] & 0x00FF))!
            print("Element count: \(elementCount),Algorithm: \(algorithm), PublicKeyAvailable: \(pubKeyType), StaticOOBAvailable: \(staticOOBType), OutputOOBSize: \(outputOOBSize), OutputOOBAction: \(outputOOBAction), InputOOBSize: \(inputOOBSize), inputOOBACtion: \(inputOOBAction)")

            //First two bytes are provisioning PDU related and are not used
            target.receivedCapabilitiesData(data.dropFirst().dropFirst())

            let nextState = StartProvisionProvisioningState(withTargetNode: target)
            
            let capabilities = (elementCount, algorithm, pubKeyType, staticOOBType, outputOOBSize, outputOOBAction, inputOOBSize, inputOOBAction)
            nextState.setCapabilities(capabilities)

            target.switchToState(nextState)
        }
   }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        //NOOP
        print("Notifications: \(characteristic.isNotifying)")
    }
}
