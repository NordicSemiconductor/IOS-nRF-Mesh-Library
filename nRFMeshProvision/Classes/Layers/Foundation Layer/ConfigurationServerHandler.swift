//
//  ConfigurationServerHandler.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 30/09/2019.
//

import Foundation

internal class ConfigurationServerHandler: ModelDelegate {
    weak var meshNetwork: MeshNetwork!
    
    let messageTypes: [UInt32 : MeshMessage.Type]
    let isSubscriptionSupported: Bool = false
    
    init(_ meshNetwork: MeshNetwork) {
        let types: [ConfigMessage.Type] = [
            ConfigCompositionDataGet.self,
            ConfigNetKeyAdd.self,
            ConfigNetKeyUpdate.self,
            ConfigNetKeyDelete.self,
            ConfigNetKeyGet.self,
            ConfigAppKeyAdd.self,
            ConfigAppKeyUpdate.self,
            ConfigAppKeyDelete.self,
            ConfigAppKeyGet.self,
            ConfigModelAppBind.self,
            ConfigModelAppUnbind.self,
            ConfigSIGModelAppGet.self,
            ConfigVendorModelAppGet.self,
            ConfigModelPublicationSet.self,
            ConfigModelPublicationVirtualAddressSet.self,
            ConfigModelPublicationGet.self,
            ConfigModelSubscriptionAdd.self,
            ConfigModelSubscriptionOverwrite.self,
            ConfigModelSubscriptionDelete.self,
            ConfigModelSubscriptionVirtualAddressAdd.self,
            ConfigModelSubscriptionVirtualAddressOverwrite.self,
            ConfigModelSubscriptionVirtualAddressDelete.self,
            ConfigModelSubscriptionDeleteAll.self,
            ConfigSIGModelSubscriptionGet.self,
            ConfigVendorModelSubscriptionGet.self,
            ConfigDefaultTtlGet.self,
            ConfigDefaultTtlSet.self,
            ConfigRelayGet.self,
            ConfigRelaySet.self,
            ConfigGATTProxyGet.self,
            ConfigGATTProxySet.self,
            ConfigFriendGet.self,
            ConfigFriendSet.self,
            ConfigBeaconGet.self,
            ConfigBeaconSet.self,
            ConfigNetworkTransmitSet.self,
            ConfigNetworkTransmitGet.self,
            ConfigNodeReset.self,
        ]
        self.meshNetwork = meshNetwork
        self.messageTypes = types.toMap()
    }
    
    func model(_ model: Model, didReceiveAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) -> MeshMessage {
        let localNode = model.parentElement.parentNode!
        
        switch request {
            
        // Composition Data
        case is ConfigCompositionDataGet:
            let compositionData = Page0(node: localNode)
            return ConfigCompositionDataStatus(report: compositionData)
            
        // Network Keys Management
        case let request as ConfigNetKeyAdd:
            let keyIndex = request.networkKeyIndex
            do {
                // Make sure the key with given index didn't exist or was identical to the
                // one in the request. Otherwise, return .keyIndexAlreadyStored.
                var networkKey = meshNetwork.networkKeys[keyIndex]
                guard networkKey == nil || networkKey!.key == request.key else {
                    return ConfigNetKeyStatus(responseTo: request, with: .keyIndexAlreadyStored)
                }
                if networkKey == nil {
                    networkKey = try meshNetwork.add(networkKey: request.key, withIndex: keyIndex,
                                                     name: "Network Key \(keyIndex + 1)")
                }
                // Add the Network Key index to the local Node.
                if let node = meshNetwork.localProvisioner?.node {
                    node.add(networkKeyWithIndex: keyIndex)
                }
                return ConfigNetKeyStatus(confirm: networkKey!)
            } catch {
                return ConfigNetKeyStatus(responseTo: request, with: .unspecifiedError)
            }
            
        case let request as ConfigNetKeyUpdate:
            let keyIndex = request.networkKeyIndex
            // If there is no such key, return .invalidNetKeyIndex.
            guard let networkKey = meshNetwork.networkKeys[keyIndex] else {
                return ConfigNetKeyStatus(responseTo: request, with: .invalidNetKeyIndex)
            }
            // Update the key data (observer will set the `oldKey` automatically).
            networkKey.key = request.key
            // And mark the key in the local Node as updated.
            if let node = meshNetwork.localProvisioner?.node {
                node.update(networkKeyWithIndex: keyIndex)
            }
            return  ConfigNetKeyStatus(confirm: networkKey)
            
        case let request as ConfigNetKeyDelete:
            let keyIndex = request.networkKeyIndex
            // Force delete the key from the global configuration.
            try? meshNetwork.remove(networkKeyWithKeyIndex: keyIndex, force: true)
            // Remove the key also from the local Node. This will also remove all
            // Application Keys bound to it.
            if let node = meshNetwork.localProvisioner?.node {
                node.remove(networkKeyWithIndex: keyIndex)
            }
            return  ConfigNetKeyStatus(responseTo: request, with: .success)
                    
        case is ConfigNetKeyGet:
            return ConfigNetKeyList(networkKeys: meshNetwork.networkKeys)
                
        // Application Key Management
        case let request as ConfigAppKeyAdd:
            let networkKeyIndex = request.networkKeyIndex
            let keyIndex = request.applicationKeyIndex
            // If the Network Key does not exist, return .invalidNetKeyIndex.
            guard let _ = meshNetwork.networkKeys[networkKeyIndex] else {
                return ConfigAppKeyStatus(responseTo: request, with: .invalidNetKeyIndex)
            }
            do {
                // Make sure the key with given index didn't exist or was identical to the
                // one in the request. Otherwise, return .keyIndexAlreadyStored.
                var applicationKey = meshNetwork.applicationKeys[keyIndex]
                guard applicationKey == nil ||
                      (applicationKey!.key == request.key &&
                      applicationKey!.boundNetworkKeyIndex == networkKeyIndex) else {
                    return ConfigAppKeyStatus(responseTo: request, with: .keyIndexAlreadyStored)
                }
                if applicationKey == nil {
                    applicationKey = try meshNetwork.add(applicationKey: request.key, withIndex: keyIndex,
                                                         name: "Application Key \(keyIndex + 1)")
                    applicationKey!.boundNetworkKeyIndex = networkKeyIndex
                }
                // Add the Network Key index to the local Node.
                if let node = meshNetwork.localProvisioner?.node {
                    node.add(applicationKeyWithIndex: keyIndex)
                }
                return ConfigAppKeyStatus(confirm: applicationKey!)
            } catch {
                return ConfigAppKeyStatus(responseTo: request, with: .unspecifiedError)
            }
            
        case let request as ConfigAppKeyUpdate:
            let networkKeyIndex = request.networkKeyIndex
            let keyIndex = request.applicationKeyIndex
            // If the Network Key does not exist, return .invalidNetKeyIndex.
            guard let _ = meshNetwork.networkKeys[networkKeyIndex] else {
                return ConfigAppKeyStatus(responseTo: request, with: .invalidNetKeyIndex)
            }
            // If the Application key does not exist, return .invalidAppKeyIndex.
            guard let applicationKey = meshNetwork.applicationKeys[keyIndex] else {
                return ConfigAppKeyStatus(responseTo: request, with: .invalidAppKeyIndex)
            }
            // If the binding is incorrect, return .invalidBinding.
            guard applicationKey.boundNetworkKeyIndex == networkKeyIndex else {
                return ConfigAppKeyStatus(responseTo: request, with: .invalidBinding)
            }
            // Update the key data (observer will set the `oldKey` automatically).
            applicationKey.key = request.key
            // And mark the key in the local Node as updated.
            if let node = meshNetwork.localProvisioner?.node {
                node.update(applicationKeyWithIndex: keyIndex)
            }
            return ConfigAppKeyStatus(confirm: applicationKey)
            
        case let request as ConfigAppKeyDelete:
            let networkKeyIndex = request.networkKeyIndex
            let keyIndex = request.applicationKeyIndex
            // If the Network Key does not exist, return .invalidNetKeyIndex.
            guard let _ = meshNetwork.networkKeys[networkKeyIndex] else {
                return ConfigAppKeyStatus(responseTo: request, with: .invalidNetKeyIndex)
            }
            // Force delete the key from the global configuration.
            try? meshNetwork.remove(applicationKeyWithKeyIndex: keyIndex, force: true)
            // Remove the key also from the local Node. This will also remove all
            // Application Keys bound to it.
            if let node = meshNetwork.localProvisioner?.node {
                node.remove(applicationKeyWithIndex: keyIndex)
            }
            return ConfigAppKeyStatus(responseTo: request, with: .success)
                
        case let request as ConfigAppKeyGet:
            let networkKeyIndex = request.networkKeyIndex
            // If the Network Key does not exist, return .invalidNetKeyIndex.
            guard let _ = meshNetwork.networkKeys[networkKeyIndex] else {
                return ConfigAppKeyList(responseTo: request, with: .invalidNetKeyIndex)
            }
            let boundAppKeys = meshNetwork.applicationKeys.filter {
                $0.boundNetworkKeyIndex == networkKeyIndex
            }
            return ConfigAppKeyList(responseTo: request, with: boundAppKeys)
                
        // Model Bindings
        case let request as ConfigModelAppBind:
            if let element = localNode.element(withAddress: request.elementAddress),
               let model = element.model(withModelId: request.modelId) {
                model.bind(applicationKeyWithIndex: request.applicationKeyIndex)
                return ConfigModelAppStatus(confirm: request)
            } else {
                return ConfigModelAppStatus(responseTo: request, with: .invalidModel)
            }
            
        case let request as ConfigModelAppUnbind:
            if let element = localNode.element(withAddress: request.elementAddress),
               let model = element.model(withModelId: request.modelId) {
                model.unbind(applicationKeyWithIndex: request.applicationKeyIndex)
                return ConfigModelAppStatus(confirm: request)
            } else {
                return ConfigModelAppStatus(responseTo: request, with: .invalidModel)
            }
            
        case let request as ConfigSIGModelAppGet:
            if let element = localNode.element(withAddress: request.elementAddress),
               let model = element.model(withModelId: request.modelId) {
                let applicationKeys = model.boundApplicationKeys
                return ConfigSIGModelAppList(responseTo: request, with: applicationKeys)
            } else {
                return ConfigSIGModelAppList(responseTo: request, with: .invalidModel)
            }
            
        case let request as ConfigVendorModelAppGet:
            if let element = localNode.element(withAddress: request.elementAddress),
               let model = element.model(withModelId: request.modelId) {
                let applicationKeys = model.boundApplicationKeys
                return ConfigVendorModelAppList(responseTo: request, with: applicationKeys)
            } else {
                return ConfigVendorModelAppList(responseTo: request, with: .invalidModel)
            }
                
        // Publications
        case let request as ConfigModelPublicationSet:
            if let element = localNode.element(withAddress: request.elementAddress),
               let model = element.model(withModelId: request.modelId) {
                // Validate request.
                guard request.publish.isCancel || meshNetwork.applicationKeys[request.publish.index] != nil else {
                    return ConfigModelPublicationStatus(responseTo: request, with: .invalidPublishParameters)
                }
                if !request.publish.isCancel {
                    // A new Group?
                    let address = request.publish.publicationAddress.address
                    if address.isGroup && address < 0xFF00 &&
                       meshNetwork.group(withAddress: request.publish.publicationAddress) == nil {
                        let group = try! Group(name: "New Group", address: address)
                        try! meshNetwork.add(group: group)
                    }
                    model.publish = request.publish
                } else {
                    model.publish = nil
                }
                return ConfigModelPublicationStatus(confirm: request)
            } else {
                return ConfigModelPublicationStatus(responseTo: request, with: .invalidModel)
            }
            
        case let request as ConfigModelPublicationVirtualAddressSet:
            if let element = localNode.element(withAddress: request.elementAddress),
                let model = element.model(withModelId: request.modelId) {
                // Validate request.
                guard meshNetwork.applicationKeys[request.publish.index] != nil else {
                    return ConfigModelPublicationStatus(responseTo: request, with: .invalidPublishParameters)
                }
                // A new Group?
                if meshNetwork.group(withAddress: request.publish.publicationAddress) == nil {
                    let group = try! Group(name: "New Group", address: request.publish.publicationAddress)
                    try! meshNetwork.add(group: group)
                }
                model.publish = request.publish
                return ConfigModelPublicationStatus(confirm: request)
            } else {
                return ConfigModelPublicationStatus(responseTo: request, with: .invalidModel)
            }
            
        case let request as ConfigModelPublicationGet:
            if let element = localNode.element(withAddress: request.elementAddress),
               let model = element.model(withModelId: request.modelId) {
                return ConfigModelPublicationStatus(responseTo: request, with: model.publish)
            } else {
                return ConfigModelPublicationStatus(responseTo: request, with: .invalidModel)
            }
                
        // Subscriptions
        case let request as ConfigModelSubscriptionAdd:
            if let element = localNode.element(withAddress: request.elementAddress),
               let model = element.model(withModelId: request.modelId) {
                guard request.address.isGroup && request.address != Address.allNodes else {
                    return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress)
                }
                guard model.delegate?.isSubscriptionSupported != false else {
                    return ConfigModelSubscriptionStatus(responseTo: request, with: .notASubscribeModel)
                }
                var group = meshNetwork.group(withAddress: MeshAddress(request.address))
                if let group = group {
                    model.subscribe(to: group)
                } else {
                    do {
                        group = try Group(name: "New Group", address: request.address)
                        try meshNetwork.add(group: group!)
                        model.subscribe(to: group!)
                    } catch {
                        return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress)
                    }
                }
                return ConfigModelSubscriptionStatus(confirmAdding: group!, to: model)
            } else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidModel)
            }
            
        case let request as ConfigModelSubscriptionOverwrite:
            if let element = localNode.element(withAddress: request.elementAddress),
               let model = element.model(withModelId: request.modelId) {
                guard request.address.isGroup && request.address != Address.allNodes else {
                    return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress)
                }
                guard model.delegate?.isSubscriptionSupported != false else {
                    return ConfigModelSubscriptionStatus(responseTo: request, with: .notASubscribeModel)
                }
                var group = meshNetwork.group(withAddress: MeshAddress(request.address))
                if let group = group {
                    model.unsubscribeFromAll()
                    model.subscribe(to: group)
                } else {
                    do {
                        group = try Group(name: "New Group", address: request.address)
                        try meshNetwork.add(group: group!)
                        model.unsubscribeFromAll()
                        model.subscribe(to: group!)
                    } catch {
                        return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress)
                    }
                }
                return ConfigModelSubscriptionStatus(confirmAdding: group!, to: model)
            } else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidModel)
            }
            
        case let request as ConfigModelSubscriptionDelete:
            if let element = localNode.element(withAddress: request.elementAddress),
               let model = element.model(withModelId: request.modelId) {
                guard request.address.isGroup && request.address != Address.allNodes else {
                    return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress)
                }
                model.unsubscribe(from: request.address)
                return ConfigModelSubscriptionStatus(confirmDeleting: request.address, from: model)
            } else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidModel)
            }
            
        case let request as ConfigModelSubscriptionVirtualAddressAdd:
            if let element = localNode.element(withAddress: request.elementAddress),
               let model = element.model(withModelId: request.modelId) {
                guard model.delegate?.isSubscriptionSupported != false else {
                    return ConfigModelSubscriptionStatus(responseTo: request, with: .notASubscribeModel)
                }
                var group = meshNetwork.group(withAddress: MeshAddress(request.virtualLabel))
                if group != nil {
                    model.subscribe(to: group!)
                } else {
                    do {
                        group = try Group(name: "New Group", address: MeshAddress(request.virtualLabel))
                        try meshNetwork.add(group: group!)
                        model.subscribe(to: group!)
                    } catch {
                        return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress)
                    }
                }
                return ConfigModelSubscriptionStatus(confirmAdding: group!, to: model)
            } else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidModel)
            }
            
        case let request as ConfigModelSubscriptionVirtualAddressOverwrite:
            if let element = localNode.element(withAddress: request.elementAddress),
               let model = element.model(withModelId: request.modelId) {
                guard model.delegate?.isSubscriptionSupported != false else {
                    return ConfigModelSubscriptionStatus(responseTo: request, with: .notASubscribeModel)
                }
                var group = meshNetwork.group(withAddress: MeshAddress(request.virtualLabel))
                if group != nil {
                    model.unsubscribeFromAll()
                    model.subscribe(to: group!)
                } else {
                    do {
                        group = try Group(name: "New Group", address: MeshAddress(request.virtualLabel))
                        try meshNetwork.add(group: group!)
                        model.unsubscribeFromAll()
                        model.subscribe(to: group!)
                    } catch {
                        return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress)
                    }
                }
                return ConfigModelSubscriptionStatus(confirmAdding: group!, to: model)
            } else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidModel)
            }
            
        case let request as ConfigModelSubscriptionVirtualAddressDelete:
            if let element = localNode.element(withAddress: request.elementAddress),
               let model = element.model(withModelId: request.modelId) {
                let address = MeshAddress(request.virtualLabel)
                if let group = meshNetwork.group(withAddress: address) {
                    model.unsubscribe(from: group)
                }
                return ConfigModelSubscriptionStatus(confirmDeleting: address.address, from: model)
            } else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidModel)
            }
            
        case let request as ConfigModelSubscriptionDeleteAll:
            if let element = localNode.element(withAddress: request.elementAddress),
               let model = element.model(withModelId: request.modelId) {
                model.unsubscribeFromAll()
                return ConfigModelSubscriptionStatus(confirmDeletingAllFrom: model)
            } else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidModel)
            }
                
        case let request as ConfigSIGModelSubscriptionGet:
            if let element = localNode.element(withAddress: request.elementAddress),
               let model = element.model(withModelId: request.modelId) {
                let addresses = model.subscriptions.map { $0.address.address }
                return ConfigSIGModelSubscriptionList(responseTo: request, with: addresses)
            } else {
                return ConfigSIGModelSubscriptionList(responseTo: request, with: .invalidModel)
            }
            
        case let request as ConfigVendorModelSubscriptionGet:
            if let element = localNode.element(withAddress: request.elementAddress),
               let model = element.model(withModelId: request.modelId) {
                let addresses = model.subscriptions.map { $0.address.address }
                return ConfigVendorModelSubscriptionList(responseTo: request, with: addresses)
            } else {
                return ConfigVendorModelSubscriptionList(responseTo: request, with: .invalidModel)
            }
                
        // Default TTL
        case let request as ConfigDefaultTtlSet:
            localNode.defaultTTL = request.ttl
            return ConfigDefaultTtlStatus(ttl: localNode.defaultTTL!)
            
        case is ConfigDefaultTtlGet:
            return ConfigDefaultTtlStatus(ttl: localNode.defaultTTL ?? 5) // TODO: networkManager.defaultTtl)
  
        // Relay settings
        case is ConfigRelayGet, is ConfigRelaySet:
            // Relay feature is not supported.
            return ConfigRelayStatus(.notSupported, count: 0, steps: 0)
   
        // GATT Proxy settings
        case is ConfigGATTProxyGet, is ConfigGATTProxySet:
            // Relay feature is not supported.
            return ConfigGATTProxyStatus(.notSupported)
    
        // Friend settings
        case is ConfigFriendGet, is ConfigFriendSet:
            // Friend feature is not supported.
            return ConfigFriendStatus(.notSupported)
                
        // Secure Network Beacon configuration
        case is ConfigBeaconGet, is ConfigBeaconSet:
            // Secure Network Beacon feature is not supported.
            return ConfigBeaconStatus(enabled: false)
            
        // Network Transmit settings
        case let request as ConfigNetworkTransmitSet:
            localNode.networkTransmit = Node.NetworkTransmit(request)
            fallthrough
            
        case is ConfigNetworkTransmitGet:
            return ConfigNetworkTransmitStatus(for: localNode)
                
        // Resetting Node
        case is ConfigNodeReset:
            // Reset the network. Keep the same Provisioner and network settings.
//            if let provisioner = meshNetwork.localProvisioner {
                // Replying with ConfigNodeResetStatus() may fail, as the network is
                // being reset and forgotten in a second.
                return ConfigNodeResetStatus()
                // TODO:
//                let localElements = meshNetwork.localElements
//                provisioner.meshNetwork = nil
//                let manager = networkManager.manager
//                    .createNewMeshNetwork(withName: meshNetwork.meshName, by: provisioner)
//                manager.localElements = localElements
//            }
            
        default:
            fatalError("Message not handled: \(request)")
        }
    }
    
    func model(_ model: Model, didReceiveUnacknowledgedMessage message: MeshMessage,
               from source: Address, sentTo destination: MeshAddress) {
        switch message {
            
        default:
            fatalError("Message not supported: \(message)")
        }
    }
    
    func model(_ model: Model, didReceiveResponse response: MeshMessage,
               toAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address) {
        switch response {
            
        default:
            fatalError("Message not supported: \(response)")
        }
    }
        
}


