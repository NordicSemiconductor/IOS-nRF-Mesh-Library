//
//  ProvisionedMeshNode.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 06/02/2018.
//

import UIKit
import CoreBluetooth

public class ProvisionedMeshNode: NSObject, ProvisionedMeshNodeProtocol {

    // MARK: - MeshNode Properties
    public  var logDelegate         : ProvisionedMeshNodeLoggingDelegate?
    public  var delegate            : ProvisionedMeshNodeDelegate?
    private var peripheral          : CBPeripheral
    private var meshNodeIdentifier  : Data
    private var proxyDataIn         : CBCharacteristic!
    private var proxyDataOut        : CBCharacteristic!
    private var proxyService        : CBService!
    private var configurationState  : ConfiguratorStateProtocol!
    private var stateManager        : MeshStateManager

    // MARK: - Configuration properties
    private var appKeyIndex: Data!
    private var netKeyIndex: Data!
    private var appKeyData:  Data!
    
    // MARK: - MeshNode implementation
    public init(withUnprovisionedNode aNode: UnprovisionedMeshNode, andDelegate aDelegate: ProvisionedMeshNodeDelegate?) {
        stateManager = MeshStateManager.restoreState()!
        peripheral          = aNode.basePeripheral()
        delegate            = aDelegate
        meshNodeIdentifier = aNode.nodeIdentifier()

        super.init()
    }

    convenience public init(withUnprovisionedNode aNode: UnprovisionedMeshNode) {
        self.init(withUnprovisionedNode: aNode, andDelegate: nil)
    }

    public func overrideBLEPeripheral(_ aPeripheral: CBPeripheral) {
        peripheral = aPeripheral
    }

    public func discover() {
        //Destination address is irrelevant here
        configurationState = DiscoveryConfiguratorState(withTargetProxyNode: self, destinationAddress: Data(), andStateManager: stateManager)
        configurationState.execute()
    }

    public func shouldDisconnect() {
        delegate?.nodeShouldDisconnect(self)
    }

    // MARK: ProvisionedMeshNodeDelegate
    // MARK: - ProvisionedMeshNodeProtocol
    func configurationCompleted() {
        delegate?.configurationSucceeded()
    }

    func completedDiscovery(withProxyService aProxyService: CBService, dataInCharacteristic aDataInCharacteristic: CBCharacteristic, andDataOutCharacteristic aDataOutCharacteristic: CBCharacteristic) {
//        logDelegate?.logDiscoveryCompleted()
        proxyService = aProxyService
        proxyDataOut = aDataOutCharacteristic
        proxyDataIn  = aDataInCharacteristic
        delegate?.nodeDidCompleteDiscovery(self)
    }

    public func nodeSubscriptionAddressAdd(_ aSubcriptionAddress: Data,
                                           onElementAddress anElementAddress: Data,
                                           modelIdentifier anIdentifier: Data,
                                           onDestinationAddress anAddress: Data) {
        let nodeSubscriptionState = ModelSubscriptionAddConfiguratorState(withTargetProxyNode: self,
                                                                          destinationAddress: anAddress,
                                                                          andStateManager: stateManager)
        nodeSubscriptionState.setSubscription(elementAddress: anElementAddress,
                                              subscriptionAddress: aSubcriptionAddress,
                                              andModelIdentifier: anIdentifier)
        
        configurationState = nodeSubscriptionState
        configurationState.execute()
    }

    public func nodePublicationAddressSet(_ aPublicationAddress: Data,
                                  onElementAddress anElementAddress: Data,
                                  appKeyIndex anAppKeyIndex: Data,
                                  credentialFlag aCredentialFlag: Bool,
                                  ttl aTTL: Data,
                                  period aPeriod: Data,
                                  retransmitCount aCount: Data,
                                  retransmitInterval anInterval: Data,
                                  modelIdentifier anIdentifier: Data,
                                  onDestinationAddress anAddress: Data) {
        let nodePublishAddressState = ModelPublicationSetConfiguratorState(withTargetProxyNode: self,
                                                                           destinationAddress: anAddress,
                                                                           andStateManager: stateManager)
        nodePublishAddressState.setPublish(elementAddress: anElementAddress,
                                           appKeyIndex: anAppKeyIndex,
                                           publishAddress: aPublicationAddress,
                                           publishTTL: aTTL,
                                           publishPeriod: aPeriod,
                                           retransmitCount: aCount,
                                           retransmitInterval: anInterval,
                                           andModelIdentifier: anIdentifier)
        configurationState = nodePublishAddressState
        configurationState.execute()
    }

    public func bindAppKey(withIndex anAppKeyIndex: Data,
                           toModelId aModelId: Data,
                           onElementAddress anElementAddress: Data,
                           onDestinationAddress anAddress: Data) {
        let bindState = ModelAppBindConfiguratorState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        bindState.setBinding(elementAddress: anElementAddress, appKeyIndex: anAppKeyIndex, andModelIdentifier: aModelId)
        configurationState = bindState
        configurationState.execute()
    }

    public func configure(destinationAddress: Data,
                          appKeyIndex aKeyIndex: Data,
                          appKeyData aKeyData: Data,
                          andNetKeyIndex aNetIndex: Data) {
        //First step of configuration is to get composition
        appKeyData  = aKeyData
        appKeyIndex = aKeyIndex
        netKeyIndex = aNetIndex
        configurationState = CompositionGetConfiguratorState(withTargetProxyNode: self, destinationAddress: destinationAddress, andStateManager: stateManager)
        configurationState.execute()
        
    }

    func switchToState(_ nextState: ConfiguratorStateProtocol) {
        print("Switching state to \(nextState.humanReadableName())")
        if nextState is AppKeyAddConfiguratorState {
            let appKeyState = nextState as! AppKeyAddConfiguratorState
            appKeyState.setAppKey(withData: appKeyData,
                                  appKeyIndex: appKeyIndex,
                                  netKeyIndex: netKeyIndex)
            configurationState = appKeyState
        } else {
            configurationState = nextState
        }
        configurationState.execute()
    }

    func basePeripheral() -> CBPeripheral {
        return peripheral
    }

    func discoveredServicesAndCharacteristics() -> (proxyService: CBService?, dataInCharacteristic: CBCharacteristic?, dataOutCharacteristic: CBCharacteristic?) {
        return (proxyService, proxyDataIn, proxyDataOut)
    }

    // MARK: - Accessors
    public func blePeripheral() -> CBPeripheral {
        return peripheral
    }
   
    public func nodeBLEName() -> String {
        return peripheral.name ?? "N/A"
    }

    public func nodeIdentifier() -> Data {
        return meshNodeIdentifier
    }

    public func humanReadableNodeIdentifier() -> String {
        let nodeIdData = Data([meshNodeIdentifier[0], meshNodeIdentifier[1]])
        return nodeIdData.hexString()
    }
   
    // MARK: - NSObject Protocols
    override public func isEqual(_ object: Any?) -> Bool {
        if let aNode = object as? ProvisionedMeshNode {
            return aNode.blePeripheral().identifier == blePeripheral().identifier
        } else {
            return false
        }
   }
}
