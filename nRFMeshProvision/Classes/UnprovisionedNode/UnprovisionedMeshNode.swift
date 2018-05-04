//
//  UnprovisionedMeshNode.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 19/12/2017.
//

import UIKit
import CoreBluetooth

public class UnprovisionedMeshNode: NSObject, UnprovisionedMeshNodeProtocol {

    // MARK: - MeshNode Properties
    public  var logDelegate         : UnprovisionedMeshNodeLoggingDelegate?
    public  var delegate            : UnprovisionedMeshNodeDelegate?
    private let peripheral          : CBPeripheral
    private let advertisementData   : [AnyHashable : Any]
    private var rssi                : NSNumber
    private var meshNodeIdentifier  : Data = Data()
    private var provisioningDataIn  : CBCharacteristic!
    private var provisioningDataOut : CBCharacteristic!
    private var provisioningService : CBService!
    private var provisioningState   : ProvisioningStateProtocol!
    
    // MARK: - Generated Data during provisioning
    private var provisioningData            : ProvisioningData!
    private var provisionerConfirmation     : Data!
    private var deviceConfirmation          : Data!
    private var provisionerRandom           : Data!
    private var deviceRandom                : Data?
    private var ecdh                        : Data!
    private var provisionerPublicKeyData    : Data!
    private var provisionerPrivateSecKey    : SecKey!
    private var devicePublicKeyData         : Data!
    private var capabilitiesProvisioningData: Data!
    private var inviteProvisioningData      : Data!
    private var startProvisioningData       : Data!
    private var userProvisionerInput        : Data!
    private var calculatedDeviceKey         : Data?

    // MARK: - MeshNode implementation
    public init(withPeripheral aPeripheral: CBPeripheral, advertisementDictionary aDictionary: [AnyHashable : Any], RSSI anRSSI: NSNumber, andDelegate aDelegate: UnprovisionedMeshNodeDelegate?) {
        peripheral          = aPeripheral
        advertisementData   = aDictionary
        delegate            = aDelegate
        meshNodeIdentifier  = Data(hexString: aPeripheral.identifier.uuidString.replacingOccurrences(of: "-", with: ""))!
        rssi = anRSSI
        super.init()
    }
   
    convenience public init(withPeripheral aPeripheral: CBPeripheral, andAdvertisementDictionary aDictionary: [AnyHashable : Any], RSSI anRSSI: NSNumber) {
        self.init(withPeripheral: aPeripheral, advertisementDictionary: aDictionary, RSSI: anRSSI, andDelegate: nil)
    }

    public func updateRSSI(_ anRSSI: NSNumber) {
        rssi = anRSSI
    }

    public func RSSI() -> NSNumber {
        return rssi
    }

    public func discover() {
        logDelegate?.logDiscoveryStarted()
        provisioningState = DiscoveryProvisioningState(withTargetNode: self)
        provisioningState.execute()
    }
   
    public func provision(withProvisioningData someProvisioningData: ProvisioningData) {
        provisioningData    = someProvisioningData
        provisioningState   = InviteProvisioningState(withTargetNode: self)
        provisioningState.execute()
    }

    public func shouldDisconnect() {
        delegate?.nodeShouldDisconnect(self)
    }
   
    // MARK: UnprovisionedMeshNodeDelegate
    func requireUserInput(anInput: @escaping ((String) -> (Void))) {
        logDelegate?.logUserInputRequired()
        delegate?.nodeRequiresUserInput(self, completionHandler: { (aString) -> (Void) in
            anInput(aString)
        })
    }

    // MARK: - UnprovisionedMeshNodeProtocol
    func provisioningUserData() -> ProvisioningData {
        return self.provisioningData
    }

    func completedDiscovery(withProvisioningService aProvisioningService: CBService, dataInCharacteristic aDataInCharacteristic: CBCharacteristic, andDataOutCharacteristic aDataOutCharacteristic: CBCharacteristic) {
        logDelegate?.logDiscoveryCompleted()
        provisioningService = aProvisioningService
        provisioningDataOut = aDataOutCharacteristic
        provisioningDataIn  = aDataInCharacteristic
        delegate?.nodeDidCompleteDiscovery(self)
    }

    func provisioningExchangeData() -> (
        inviteData: Data,
        capabilitiesData: Data,
        startData: Data,
        provisionerKeyData: Data,
        deviceKeyData: Data,
        ecdhData: Data) {
            let exchangedData = (inviteData: inviteProvisioningData!,
                                 capabilitiesData: capabilitiesProvisioningData!,
                                 startData: startProvisioningData!,
                                 provisionerKeyData: provisionerPublicKeyData!,
                                 deviceKeyData: devicePublicKeyData!,
                                 ecdhData:ecdh!)
            return exchangedData
    }

    func provisionerPrivateKey() -> SecKey {
        return provisionerPrivateSecKey
    }

    func generatedProvisionerPrivateKey(_ someKey: SecKey) {
        provisionerPrivateSecKey = someKey
    }

    func deviceKey() -> Data? {
        return calculatedDeviceKey
    }
   
    func calculatedDeviceKey(_ aDeviceKey: Data) {
        calculatedDeviceKey = aDeviceKey
    }

    func provisioningConfirmationData() -> (
        provisionerRandom       : Data,
        deviceRandom            : Data?,
        provisionerConfirmation : Data,
        deviceConfirmation      : Data
        ) {
            let confirmationData = (provisionerRandom: provisionerRandom!,
                                    deviceRandom: deviceRandom,
                                    provisionerConfirmation: provisionerConfirmation!,
                                    deviceConfirmation: deviceConfirmation!)
            return confirmationData
    }
   
    func provisionerAuthData() -> Data {
        return userProvisionerInput
    }

    func receivedCapabilitiesData(_ someData: Data) {
        logDelegate?.logReceivedCapabilitiesData(withMessage: "0x\(someData.hexString())")
        capabilitiesProvisioningData = someData
    }
   
    func generatedProvisioningStartData(_ someData: Data) {
        logDelegate?.logGeneratedProvisioningStartData(withMessage: "0x\(someData.hexString())")
        startProvisioningData = someData
    }
   
    func generatedProvisioningInviteData(_ someData: Data) {
        logDelegate?.logGenratedProvisionInviteData(withMessage: "0x\(someData.hexString())")
        inviteProvisioningData = someData
    }
   
    func generatedProvisionerPublicKeyData(_ someData: Data) {
        logDelegate?.logGenerateKeypair(withMessage: "0x\(someData.hexString())")
        provisionerPublicKeyData = someData
    }

    func receivedDevicePublicKeyData(_ someData: Data) {
        logDelegate?.logReceivedDevicePublicKey(withMessage: "0x\(someData.hexString())")
        devicePublicKeyData = someData
    }

    func calculatedECDH(_ anECDH: Data) {
        logDelegate?.logCalculatedECDH(withMessage: "0x\(anECDH.hexString())")
        ecdh = anECDH
    }
   
    func generatedProvisionerRandom(_ aRandomValue: Data) {
        logDelegate?.logGeneratedProvisionerRandom(withMessage: "0x\(aRandomValue.hexString())")
        provisionerRandom = aRandomValue
    }
   
    func receivedDeviceRandom(_ aRandomValue: Data) {
        logDelegate?.logReceivedDeviceRandom(withMessage: "0x\(aRandomValue.hexString())")
        deviceRandom = aRandomValue
    }
   
    func generatedProvisionerConfirmationValue(_ aConfirmationValue: Data) {
        logDelegate?.logGeneratedProvisionerConfirmationValue(withMessage: "0x\(aConfirmationValue.hexString())")
        provisionerConfirmation = aConfirmationValue
    }
   
    func receivedDeviceConfirmationValue(_ aConfirmationValue: Data) {
        logDelegate?.logGeneratedProvisionerConfirmationValue(withMessage: "0x\(aConfirmationValue.hexString())")
        deviceConfirmation = aConfirmationValue
    }
   
    func receivedProvisionerUserInput(_ aUserInput: Data) {
        logDelegate?.logUserInputCompleted(withMessage: "0x\(aUserInput.hexString())")
        userProvisionerInput = aUserInput
    }

    func switchToState(_ nextState: ProvisioningStateProtocol) {
        logDelegate?.logSwitchedToProvisioningState(withMessage: nextState.humanReadableName())
        provisioningState = nextState
        nextState.execute()
    }
   
    func basePeripheral() -> CBPeripheral {
        return peripheral
    }

    func discoveredServicesAndCharacteristics() -> (provisionService: CBService?, dataInCharacteristic: CBCharacteristic?, dataOutCharacteristic: CBCharacteristic?) {
        return (provisioningService, provisioningDataIn, provisioningDataOut)
    }

    func provisioningSucceeded(withServicesChanged: Bool) {
        if withServicesChanged {
            print("services changed, don't recnonect")
            delegate?.nodeProvisioningCompleted(self)
        } else {
            print("No services chagned, a reconnect is needed")
            delegate?.nodeProvisioningCompleted(self)
        }
    }
   
    func provisioningFailed(withErrorCode anErrorCode: ProvisioningErrorCodes) {
        delegate?.nodeProvisioningFailed(self, withErrorCode: anErrorCode)
    }
   // MARK: - Accessors
    public func blePeripheral() -> CBPeripheral {
        return peripheral
    }
   
    public func nodeBLEName() -> String {
        return peripheral.name ?? "N/A"
    }
   
    public func humanReadableNodeIdentifier() -> String {
        let nodeIdData = Data([meshNodeIdentifier[0], meshNodeIdentifier[1]])
        return nodeIdData.hexString()
    }
   
    public func nodeIdentifier() -> Data {
        return meshNodeIdentifier
    }
   
    public func getNodeEntryData() -> MeshNodeEntry? {
        var anEntry: MeshNodeEntry?
        let timestamp = Date()
        if let deviceKey = deviceKey() {
            anEntry = MeshNodeEntry(withName: provisioningData.friendlyName, provisionDate: timestamp, nodeId: nodeIdentifier(), andDeviceKey: deviceKey)
        }
        return anEntry
    }

    // MARK: - NSObject Protocols
    override public func isEqual(_ object: Any?) -> Bool {
        if let aNode = object as? UnprovisionedMeshNode {
            return aNode.blePeripheral().identifier == blePeripheral().identifier
        } else {
            return false
        }
   }
}
