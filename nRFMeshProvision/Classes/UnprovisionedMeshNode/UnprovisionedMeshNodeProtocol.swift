//
//  UnprovisionedMeshNodeProtocol.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 20/12/2017.
//

import Foundation
import CoreBluetooth

protocol UnprovisionedMeshNodeProtocol {
    
    // MARK: - Properties
    var logDelegate         : UnprovisionedMeshNodeLoggingDelegate? {set get}
    var delegate            : UnprovisionedMeshNodeDelegate? {set get}

    // MARK: - Accessors
    func basePeripheral() -> CBPeripheral
    
    func discoveredServicesAndCharacteristics() -> (
        provisionService: CBService?,
        dataInCharacteristic: CBCharacteristic?,
        dataOutCharacteristic: CBCharacteristic?
    )
    
    func provisioningExchangeData() -> (
        inviteData          : Data,
        capabilitiesData    : Data,
        startData           : Data,
        provisionerKeyData  : Data,
        deviceKeyData       : Data,
        ecdhData            : Data
    )

    func provisionerAuthData() -> Data

    func provisionerPrivateKey() -> SecKey

    func provisioningConfirmationData() -> (
        provisionerRandom       : Data,
        deviceRandom            : Data?,
        provisionerConfirmation : Data,
        deviceConfirmation      : Data
    )

    func provisioningUserData() -> ProvisioningData
    func deviceKey() -> Data?

    // MARK: - Property updates
    func completedDiscovery(withProvisioningService aProvisioningService: CBService,
                            dataInCharacteristic aDataInCharacteristic: CBCharacteristic,
                            andDataOutCharacteristic aDataOutCharacteristic: CBCharacteristic)
    func generatedProvisioningInviteData(_ someData: Data)
    func generatedProvisioningStartData(_ someData: Data)
    func generatedProvisionerPublicKeyData(_ someData: Data)
    func generatedProvisionerPrivateKey(_ someKey: SecKey)
    func receivedCapabilitiesData(_ someData: Data)
    func parsedCapabilities(_ someCapabilities: InviteCapabilities)
    func receivedDevicePublicKeyData(_ someData: Data)
    func calculatedECDH(_ anECDH: Data)
    func generatedProvisionerRandom(_ aRandomValue: Data)
    func receivedDeviceRandom(_ aRandomValue: Data)
    func generatedProvisionerConfirmationValue(_ aConfirmationValue: Data)
    func receivedDeviceConfirmationValue(_ aConfirmationValue: Data)
    func receivedProvisionerUserInput(_ aUserInput: Data)
    func provisioningSucceeded(withServicesChanged: Bool)
    func provisioningFailed(withErrorCode anErrorCode: ProvisioningErrorCodes)
    func calculatedDeviceKey(_ aDeviceKey: Data)

    // MARK: - Data input
    func requireUserInput(outputActionType: OutputOutOfBoundActions, outputLength: UInt8, anInput: (@escaping (_ value: String) -> (Void)))

    // MARK: - State related
    func switchToState(_ nextState : ProvisioningStateProtocol)
    func shouldDisconnect()
}
