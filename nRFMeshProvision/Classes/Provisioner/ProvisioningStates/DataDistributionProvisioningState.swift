//
//  DataDistributionProvisioningState.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 29/12/2017.
//

import Foundation
import CoreBluetooth
import Security

class DataDistributionProvisioningState: NSObject, ProvisioningStateProtocol {

    // MARK: - Properties
    private var provisioningService: CBService!
    private var dataInCharacteristic: CBCharacteristic!
    private var dataOutCharacteristic: CBCharacteristic!
    // MARK: - State properties
    private var servicesChanged: Bool = false
    //SAR with Provisioning PDU (0x03) (0x43, 0x83 and 0xC3)
    let provDataSARStart: UInt8 = 0x43
    let provDataSARContinue: UInt8 = 0x83
    let provDataSARLast: UInt8 = 0xC3

    func humanReadableName() -> String {
        return "Provisioning data"
    }

    // MARK: - ProvisioningStateProtocol
    var target: UnprovisionedMeshNodeProtocol
    
    required init(withTargetNode aNode: UnprovisionedMeshNodeProtocol) {
        target = aNode
        super.init()
        target.basePeripheral().delegate = self
        
        //If services and characteristics are already discovered, set them now
        let discovery           = target.discoveredServicesAndCharacteristics()
        provisioningService     = discovery.provisionService
        dataInCharacteristic    = discovery.dataInCharacteristic
        dataOutCharacteristic   = discovery.dataOutCharacteristic
    }
   
    func execute() {
        let helper                      = OpenSSLHelper()
        //Step 1: Calculate Provisioning Salt
        let confirmationInputs          = generateConfirmationInputsFromTarget(target)
        let confirmationSalt            = helper.calculateSalt(confirmationInputs)!
        let provisionerRandom           = target.provisioningConfirmationData().provisionerRandom
        let deviceRandom                = target.provisioningConfirmationData().deviceRandom!
        let provisioningSaltInputData   = confirmationSalt + provisionerRandom + deviceRandom
        
        let provisioningSalt            = helper.calculateSalt(provisioningSaltInputData)!

        let ecdh                        = target.provisioningExchangeData().ecdhData
        let t                           = helper.calculateCMAC(ecdh, andKey: provisioningSalt)!

        //Step 2: Calculate SessionKey
        let sessionKeyP                 = Data([0x70, 0x72, 0x73, 0x6B]) //PRSK string
        let sessionKey                  = helper.calculateCMAC(sessionKeyP, andKey: t)
        
        //Step 3: Calculate Session Nonce
        let sessionNonceP               = Data([0x70, 0x72, 0x73, 0x6E]) //PRSN string
        var sessionNonce                = helper.calculateCMAC(sessionNonceP, andKey: t)
        //Only the 13 LSB is the Session Nonce, drop first 3 bytes
        sessionNonce                    = sessionNonce?.dropFirst(3)

        //Step 4: Calculate Device Key
        let deviceKeyP                  = Data([0x70, 0x72, 0x64, 0x6B]) //PRDK string
        let deviceKey                   = helper.calculateCMAC(deviceKeyP, andKey: t)

        target.calculatedDeviceKey(deviceKey!)

        //Step 4: Get Provisioning Data
        let provData = target.provisioningUserData()

        print("Provisioning Salt    = \(provisioningSalt.hexString())")
        print("Session Key          = \(sessionKey!.hexString())")
        print("Session Nonce        = \(sessionNonce!.hexString())")
        print("NetKey               = \(provData.netKey.hexString())")
        print("DeviceKey            = \(deviceKey!.hexString())")
        print("KeyIndex             = \(provData.keyIndex.hexString())")
        print("Flags                = \(provData.flags.hexString())")
        print("IV Index             = \(provData.ivIndex.hexString())")
        print("Unicast Address      = \(provData.unicastAddr.hexString())")

        let provisioningData = provData.netKey + provData.keyIndex + provData.flags + provData.ivIndex + provData.unicastAddr
        print("Provisioning data: \(provisioningData.hexString())")

        //Step 5: Encrypt provisioning data
        if let encryptedData = helper.calculateCCM(provisioningData, withKey: sessionKey, nonce: sessionNonce!, dataSize: 25, andMICSize: 8) {
            //Step 6: Send data
            let maximumWriteLength = target.basePeripheral().maximumWriteValueLength(for: .withoutResponse)
            let provisioningDataOpCode: UInt8 = 0x07
            //2 bytes are added for provisioning PDU (0x03) + provisioning data PDU (0x07)
            if maximumWriteLength >= encryptedData.count + 2 {
                //No segmentation necessary
                let provisioningDataPDU = Data([0x03,provisioningDataOpCode]) + encryptedData
                print("Provisioning data PDU: \(provisioningDataPDU.hexString())")
                print("No segmentation necessary to send provisioning data, write length = \(maximumWriteLength)")
                target.basePeripheral().writeValue(provisioningDataPDU, for: dataInCharacteristic, type: .withoutResponse)
            } else {
                print("maximum write length \(maximumWriteLength) is shorter than provisioning data PDU, will Segment")
                var segmentedProvisioningData  : [Data] = [Data]()
                segmentedProvisioningData.append(Data(bytes:[provDataSARStart, provisioningDataOpCode]))
                segmentedProvisioningData[0].append(contentsOf: encryptedData[0..<18])
                segmentedProvisioningData.append(Data(bytes:[provDataSARLast]))
                segmentedProvisioningData[1].append(contentsOf: encryptedData[18..<33])
                print("\((Data([0x03,provisioningDataOpCode]) + encryptedData).hexString())")
                for aSegment in segmentedProvisioningData {
                    print("Provisioning Data: \(aSegment.hexString())")
                    if aSegment[0] == provDataSARStart {
                        print("Provisioning data SAR Start: 0x47, Part \(segmentedProvisioningData.index(of: aSegment)!) of \(segmentedProvisioningData.count)")
                    } else if aSegment[0] == provDataSARContinue {
                        print("Provisioning data SAR Continue: 0x87, Part \(segmentedProvisioningData.index(of: aSegment)!) of \(segmentedProvisioningData.count)")
                    } else if aSegment[0] == provDataSARLast {
                        print("Provisioning data SAR Last: 0xC7, Part \(segmentedProvisioningData.index(of: aSegment)!) of \(segmentedProvisioningData.count)")
                    }
                    target.basePeripheral().writeValue(aSegment, for: dataInCharacteristic, type: .withoutResponse)
                }
       }
   } else {
            print("Failed to encrypt data!, disconnecting")
            target.shouldDisconnect()
        }
   //On sucess, the peripheral is provisioned and will change service list
    }

    private func generateConfirmationInputsFromTarget(_ aTarget: UnprovisionedMeshNodeProtocol) -> Data {
        let data      = aTarget.provisioningExchangeData()
        //Invite: 1 bytes, Capabilities: 11 bytes, Start: 5 bytes, ProvisionerKey: 64 bytes, DeviceKey: 64 bytes
        return data.inviteData + data.capabilitiesData + data.startData + data.provisionerKeyData + data.deviceKeyData
    }

    // MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        if invalidatedServices.contains(provisioningService) {
            print("Provisioning service invalidated")
            print("Setting service changed flag to avoid an unneccessary reconnect")
            servicesChanged = true
        }
   }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        //NOOP
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        //NOOP
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let aValue = characteristic.value {
            print(aValue.hexString())
            guard aValue[0] == 0x03 else {
                print("Received unexpected PDU 0x\(aValue[0]), 0x03 expected")
                return
            }
            if aValue[1] == 0x08 {
                print("Provisioning succeeded, will delay 1 second to check if service change")
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0, execute: {
                    self.target.provisioningSucceeded(withServicesChanged: self.servicesChanged)
                })
            } else if aValue[1] == 0x09 {
                if let errorCode = ProvisioningErrorCodes(rawValue: aValue[2]) {
                    target.provisioningFailed(withErrorCode: errorCode)
                } else {
                    target.provisioningFailed(withErrorCode: .unexpectedError)
                }
       }
    }
   }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        //NOOP
    }
}
