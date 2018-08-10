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
    private var genericControllerState: GenericModelControllerStateProtocol!
    private var stateManager        : MeshStateManager
    
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
        proxyService = aProxyService
        proxyDataOut = aDataOutCharacteristic
        proxyDataIn  = aDataInCharacteristic
        delegate?.nodeDidCompleteDiscovery(self)
    }

    public func nodeSubscriptionAddressAdd(_ aSubcriptionAddress: Data,
                                           onElementAddress anElementAddress: Data,
                                           modelIdentifier anIdentifier: Data,
                                           onDestinationAddress anAddress: Data) {
        let nodeSubscriptionAddState = ModelSubscriptionAddConfiguratorState(withTargetProxyNode: self,
                                                                          destinationAddress: anAddress,
                                                                          andStateManager: stateManager)
        nodeSubscriptionAddState.setSubscription(elementAddress: anElementAddress,
                                              subscriptionAddress: aSubcriptionAddress,
                                              andModelIdentifier: anIdentifier)
        
        configurationState = nodeSubscriptionAddState
        configurationState.execute()
    }

    public func nodeSubscriptionAddressDelete(_ aSubcriptionAddress: Data,
                                           onElementAddress anElementAddress: Data,
                                           modelIdentifier anIdentifier: Data,
                                           onDestinationAddress anAddress: Data) {
        let nodeSubscriptionDeleteState = ModelSubscriptionDeleteConfiguratorState(withTargetProxyNode: self,
                                                                          destinationAddress: anAddress,
                                                                          andStateManager: stateManager)
        nodeSubscriptionDeleteState.setSubscription(elementAddress: anElementAddress,
                                              subscriptionAddress: aSubcriptionAddress,
                                              andModelIdentifier: anIdentifier)
        
        configurationState = nodeSubscriptionDeleteState
        configurationState.execute()
    }

    public func nodeGenericOnOffSet(_ anElementAddress: Data, onDestinationAddress anAddress: Data, withtargetState aState: Data) {
        let setState = GenericOnOffSetControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        setState.setTargetState(aTargetState: aState)
        genericControllerState = setState
        genericControllerState.execute()
    }

    public func nodeGenericOnOffGet(_ anElementAddress: Data, onDestinationAddress anAddress: Data) {
        let getState = GenericOnOffGetControllerState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress, andStateManager: stateManager)
        genericControllerState = getState
        genericControllerState.execute()
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
                                           credentialFlag: aCredentialFlag,
                                           publishAddress: aPublicationAddress,
                                           publishTTL: aTTL,
                                           publishPeriod: aPeriod,
                                           retransmitCount: aCount,
                                           retransmitInterval: anInterval,
                                           andModelIdentifier: anIdentifier)
        configurationState = nodePublishAddressState
        configurationState.execute()
    }

    public func appKeyDelete(atIndex anAppKeyIndex: Data,
                             forNetKeyAtIndex aNetKeyIndex: Data,
                             onDestinationAddress anAddress: Data) {
        let deleteKeyState = AppKeyDeleteConfiguratorState(withTargetProxyNode: self,
                                                     destinationAddress: anAddress,
                                                     andStateManager: stateManager)
        deleteKeyState.setAppKeyIndex(anAppKeyIndex, andNetKeyIndex: aNetKeyIndex)
        configurationState = deleteKeyState
        configurationState.execute()
    }

    public func appKeyAdd(_ anAppKey: Data,
                          atIndex anIndex: Data,
                          forNetKeyAtIndex aNetKeyIndex: Data,
                          onDestinationAddress anAddress: Data) {
        let addKeyState = AppKeyAddConfiguratorState(withTargetProxyNode: self,
                                                     destinationAddress: anAddress,
                                                     andStateManager: stateManager)
        addKeyState.setAppKey(withData: anAppKey, appKeyIndex: anIndex, netKeyIndex: aNetKeyIndex)
        configurationState = addKeyState
        configurationState.execute()
    }

    public func bindAppKey(withIndex anAppKeyIndex: Data,
                           modelId aModelId: Data,
                           elementAddress anElementAddress: Data,
                           onDestinationAddress anAddress: Data) {
        let bindState = ModelAppBindConfiguratorState(withTargetProxyNode: self,
                                                      destinationAddress: anAddress,
                                                      andStateManager: stateManager)
        bindState.setBinding(elementAddress: anElementAddress, appKeyIndex: anAppKeyIndex, andModelIdentifier: aModelId)
        configurationState = bindState
        configurationState.execute()
    }
    
    public func unbindAppKey(withIndex anAppKeyIndex: Data,
                             modelId aModelId: Data,
                             elementAddress anElementAddress: Data,
                             onDestinationAddress anAddress: Data) {
        let unbindState = ModelAppUnbindConfiguratorState(withTargetProxyNode: self,
                                                        destinationAddress: anAddress,
                                                        andStateManager: stateManager)
        unbindState.setUnbinding(elementAddress: anElementAddress, appKeyIndex: anAppKeyIndex, andModelIdentifier: aModelId)
        configurationState = unbindState
        configurationState.execute()
    }

    public func resetNode(destinationAddress: Data) {
        configurationState = NodeResetConfiguratorState(withTargetProxyNode: self, destinationAddress: destinationAddress, andStateManager: stateManager)
        configurationState.execute()
    }

    public func configure(destinationAddress: Data) {
        //First step of configuration is to get composition
        configurationState = CompositionGetConfiguratorState(withTargetProxyNode: self, destinationAddress: destinationAddress, andStateManager: stateManager)
        configurationState.execute()
        
    }

    func switchToState(_ nextState: ConfiguratorStateProtocol) {
        print("Switching state to \(nextState.humanReadableName())")
        configurationState = nextState
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
