//
//  RandomConfirmationProvisioningState.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 27/12/2017.
//

import Foundation
import CoreBluetooth
import Security

class RandomConfirmationProvisioningState: NSObject, ProvisioningStateProtocol {

    // MARK: - Properties
    private var provisioningService: CBService!
    private var dataInCharacteristic: CBCharacteristic!
    private var dataOutCharacteristic: CBCharacteristic!
    
    // MARK: - State properties
    private var provisionerRandom       : Data!
    private var deviceRandom            : Data!
    private var provisionerConfirmation : Data!
    private var deviceConfirmation      : Data!

    // MARK: - ProvisioningStateProtocol
    var target: UnprovisionedMeshNodeProtocol

    func humanReadableName() -> String {
        return "Random confirmation"
    }

    required init(withTargetNode aNode: UnprovisionedMeshNodeProtocol) {
        target = aNode
        super.init()
        target.basePeripheral().delegate = self
        //If services and characteristics are already discovered, set them now
        let discovery = target.discoveredServicesAndCharacteristics()
        provisioningService     = discovery.provisionService
        dataInCharacteristic    = discovery.dataInCharacteristic
        dataOutCharacteristic   = discovery.dataOutCharacteristic
        
        //Get properties from previous state
        let confirmationData    = target.provisioningConfirmationData()
        provisionerRandom       = confirmationData.provisionerRandom
        provisionerConfirmation = confirmationData.provisionerConfirmation
        deviceConfirmation      = confirmationData.deviceConfirmation
    }

    func execute() {
        //Send provisioner generated random so device confirms and sends back it's deviceRandom
        let provisionerRandomConfirmationPDU = Data([0x03, 0x06]) + provisionerRandom
        target.basePeripheral().writeValue(provisionerRandomConfirmationPDU, for: dataInCharacteristic, type: .withoutResponse)
    }

    private func generateConfirmationInputsFromTarget(_ aTarget: UnprovisionedMeshNodeProtocol) -> Data {
        let data = aTarget.provisioningExchangeData()
        //invite: 1 bytes, capabilities: 11 bytes, start: 5 bytes, provisionerKey: 64 bytes, deviceKey: 64 bytes
        return data.inviteData + data.capabilitiesData + data.startData + data.provisionerKeyData + data.deviceKeyData
    }

    func confirmDeviceRandom(_ aRandom: Data) -> Bool {
        //Generate ConfirmationInputs
        let confirmationInputs = generateConfirmationInputsFromTarget(target)
        let helper = OpenSSLHelper()
        //Get salt (S1 function) from confirmationInputs.
        let salt = helper.calculateSalt(confirmationInputs)
        let ecdh = target.provisioningExchangeData().ecdhData
        //N = ECDH Secret, SALT = S1 & P = "prck" in hex ASCII (0x70, 0x72, 0x63, 0x6b)
        let confirmationKey = helper.calculateK1(withN: ecdh, salt: salt, andP: Data([0x70, 0x72, 0x63, 0x6b]))
        //Next step is to calculate the confirmation provisioner value
        //This is done by calculating AES-CMAC of (Random value || AuthVAlue) with salt (confirmationKey)
        let authBytes = target.provisionerAuthData()
        let confirmationData = aRandom + authBytes
        let confirmationValue = helper.calculateCMAC(confirmationData, andKey: confirmationKey!)
        if confirmationValue == target.provisioningConfirmationData().deviceConfirmation {
            return true
        } else {
            return false
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
        if let randomPDU = characteristic.value {
            guard randomPDU[0] == 0x03 && randomPDU[1] == 0x06 else {
                print("Wrong PDU, expected 0306")
                print("Received \(randomPDU[0])\(randomPDU[1]) instead.")
                return
            }
            //First two bytes are PDU related, and not used for verifications
            let deviceRandom = randomPDU.dropFirst().dropFirst()
            target.receivedDeviceRandom(deviceRandom)
            if confirmDeviceRandom(deviceRandom) {
                let nextState = DataDistributionProvisioningState(withTargetNode: target)
                target.switchToState(nextState)
            } else {
                print("Confirmation values did not match!, disconnect.")
                target.shouldDisconnect()
            }
   } else {
            print("ERROR: Received no data for Random PDU..")
            print("Expected value: 0x0306<deviceRandom>, received Nil instead")
        }
   }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        //NOOP
    }
}
