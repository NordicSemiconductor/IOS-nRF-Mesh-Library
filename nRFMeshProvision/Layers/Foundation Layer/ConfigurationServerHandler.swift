/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

internal class ConfigurationServerHandler: ModelDelegate {
    weak var meshNetwork: MeshNetwork!
    
    let messageTypes: [UInt32 : MeshMessage.Type]
    let isSubscriptionSupported: Bool = false
    let publicationMessageComposer: MessageComposer? = nil
    
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
            ConfigNodeIdentityGet.self,
            ConfigNodeIdentitySet.self,
            ConfigNodeReset.self,
            ConfigHeartbeatPublicationGet.self,
            ConfigHeartbeatPublicationSet.self,
            ConfigHeartbeatSubscriptionGet.self,
            ConfigHeartbeatSubscriptionSet.self,
            ConfigKeyRefreshPhaseGet.self,
            ConfigKeyRefreshPhaseSet.self,
            ConfigLowPowerNodePollTimeoutGet.self,
        ]
        self.meshNetwork = meshNetwork
        self.messageTypes = types.toMap()
    }
    
    func model(_ model: Model, didReceiveAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) -> MeshResponse {
        let localNode = model.parentElement!.parentNode!
        
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
                    networkKey = try meshNetwork.add(networkKey: request.key,
                                                     withIndex: keyIndex,
                                                     name: "Network Key \(keyIndex + 1)")
                }
                // Add the Network Key index to the local Node.
                localNode.add(networkKeyWithIndex: keyIndex)
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
            // The Network Key can only be changed once if a single Key Refresh Procedure.
            // Otherwise, return .keyIndexAlreadyStored.
            guard networkKey.phase == .normalOperation ||
                 (networkKey.phase == .keyDistribution && networkKey.key == request.key) else {
                return ConfigNetKeyStatus(responseTo: request, with: .keyIndexAlreadyStored)
            }
            if networkKey.phase == .normalOperation {
                // Update the key data (observer will set the `oldKey` automatically).
                networkKey.key = request.key
                // And mark the key in the local Node as updated.
                localNode.update(networkKeyWithIndex: keyIndex)
            }
            return ConfigNetKeyStatus(confirm: networkKey)
            
        case let request as ConfigNetKeyDelete:
            let keyIndex = request.networkKeyIndex
            // When an element receives a Config NetKey Delete message that identifies a
            // Network Key that is not in the Network Key List, it responds with Success,
            // because the result of deleting the key that does not exist in the Network Key
            // List will be the same as if the key was deleted from the List.
            guard let _ = meshNetwork.networkKeys[keyIndex] else {
                return ConfigNetKeyStatus(responseTo: request, with: .success)
            }
            // It is not possible to remove the last key.
            guard meshNetwork.networkKeys.count > 1 else {
                return ConfigNetKeyStatus(responseTo: request, with: .cannotRemove)
            }
            // Force delete the key from the global configuration.
            try? meshNetwork.remove(networkKeyWithKeyIndex: keyIndex, force: true)
            // Remove the key also from the local Node. This will also remove all
            // Application Keys bound to it.
            localNode.remove(networkKeyWithIndex: keyIndex)
            return ConfigNetKeyStatus(responseTo: request, with: .success)
                    
        case is ConfigNetKeyGet:
            return ConfigNetKeyList(networkKeys: meshNetwork.networkKeys)
                
        // Application Key Management
        case let request as ConfigAppKeyAdd:
            // If the Network Key does not exist, return .invalidNetKeyIndex.
            guard let networkKey = meshNetwork.networkKeys[request.networkKeyIndex] else {
                return ConfigAppKeyStatus(responseTo: request, with: .invalidNetKeyIndex)
            }
            let keyIndex = request.applicationKeyIndex
            do {
                // Make sure the key with given index didn't exist or was identical to the
                // one in the request. Otherwise, return .keyIndexAlreadyStored.
                var applicationKey = meshNetwork.applicationKeys[keyIndex]
                guard applicationKey == nil ||
                      (applicationKey!.key == request.key &&
                      applicationKey!.isBound(to: networkKey)) else {
                    return ConfigAppKeyStatus(responseTo: request, with: .keyIndexAlreadyStored)
                }
                if applicationKey == nil {
                    applicationKey = try meshNetwork.add(applicationKey: request.key,
                                                         withIndex: keyIndex,
                                                         name: "Application Key \(keyIndex + 1)")
                    applicationKey!.boundNetworkKeyIndex = networkKey.index
                }
                // Add the Network Key index to the local Node.
                localNode.add(applicationKeyWithIndex: keyIndex)
                return ConfigAppKeyStatus(confirm: applicationKey!)
            } catch {
                return ConfigAppKeyStatus(responseTo: request, with: .unspecifiedError)
            }
            
        case let request as ConfigAppKeyUpdate:
            // If the Network Key does not exist, return .invalidNetKeyIndex.
            guard let networkKey = meshNetwork.networkKeys[request.networkKeyIndex] else {
                return ConfigAppKeyStatus(responseTo: request, with: .invalidNetKeyIndex)
            }
            let keyIndex = request.applicationKeyIndex
            // If the Application key does not exist, return .invalidAppKeyIndex.
            guard let applicationKey = meshNetwork.applicationKeys[keyIndex] else {
                return ConfigAppKeyStatus(responseTo: request, with: .invalidAppKeyIndex)
            }
            // If the binding is incorrect, return .invalidBinding.
            guard applicationKey.isBound(to: networkKey) else {
                return ConfigAppKeyStatus(responseTo: request, with: .invalidBinding)
            }
            // Updating Application Key is only possible during Key Refresh Procedure
            // for the bound Network Key. Otherwise, return .cannotUpdate.
            guard case .keyDistribution = networkKey.phase else {
                return ConfigAppKeyStatus(responseTo: request, with: .cannotUpdate)
            }
            // The key cannot be changed multiple times in a single Key Refresh Procedure.
            // Otherwise, return .keyIndexAlreadyStored.
            guard applicationKey.oldKey == nil || applicationKey.key == request.key else {
                return ConfigAppKeyStatus(responseTo: request, with: .keyIndexAlreadyStored)
            }
            if applicationKey.oldKey == nil {
                // Update the key data (observer will set the `oldKey` automatically).
                applicationKey.key = request.key
                // And mark the key in the local Node as updated.
                localNode.update(applicationKeyWithIndex: keyIndex)
            }
            return ConfigAppKeyStatus(confirm: applicationKey)
            
        case let request as ConfigAppKeyDelete:
            // If the Network Key does not exist, return .invalidNetKeyIndex.
            guard let networkKey = meshNetwork.networkKeys[request.networkKeyIndex] else {
                return ConfigAppKeyStatus(responseTo: request, with: .invalidNetKeyIndex)
            }
            let keyIndex = request.applicationKeyIndex
            // When an element receives a Config AppKey Delete message that identifies
            // an Application Key that is not in the Application Key List, it responds
            // with Success, because the result of deleting the key that does not exist
            // in the Application Key List will be the same as if the key was deleted
            // from the AppKey List.
            guard let applicationKey = meshNetwork.applicationKeys[keyIndex] else {
                return ConfigAppKeyStatus(responseTo: request, with: .success)
            }
            // Check if the binding is correct. Otherwise, returner .invalidBinding.
            guard applicationKey.isBound(to: networkKey) else {
                return ConfigAppKeyStatus(responseTo: request, with: .invalidBinding)
            }
            // Force delete the key from the global configuration.
            try? meshNetwork.remove(applicationKeyWithKeyIndex: keyIndex, force: true)
            // Remove the key also from the local Node. This will also remove all
            // Application Keys bound to it.
            localNode.remove(applicationKeyWithIndex: keyIndex)
            return ConfigAppKeyStatus(responseTo: request, with: .success)
                
        case let request as ConfigAppKeyGet:
            // If the Network Key does not exist, return .invalidNetKeyIndex.
            guard let networkKey = meshNetwork.networkKeys[request.networkKeyIndex] else {
                return ConfigAppKeyList(responseTo: request, with: .invalidNetKeyIndex)
            }
            let boundAppKeys = meshNetwork.applicationKeys.boundTo(networkKey)
            return ConfigAppKeyList(responseTo: request, with: boundAppKeys)
                
        // Model Bindings
        case let request as ConfigModelAppBind:
            guard let element = localNode.element(withAddress: request.elementAddress) else {
                return ConfigModelAppStatus(responseTo: request, with: .invalidAddress)
            }
            guard let model = element.model(withModelId: request.modelId) else {
                return ConfigModelAppStatus(responseTo: request, with: .invalidModel)
            }
            guard let _ = meshNetwork.applicationKeys[request.applicationKeyIndex] else {
                return ConfigModelAppStatus(responseTo: request, with: .invalidAppKeyIndex)
            }
            model.bind(applicationKeyWithIndex: request.applicationKeyIndex)
            return ConfigModelAppStatus(confirm: request)
            
        case let request as ConfigModelAppUnbind:
            guard let element = localNode.element(withAddress: request.elementAddress) else {
                return ConfigModelAppStatus(responseTo: request, with: .invalidAddress)
            }
            guard let model = element.model(withModelId: request.modelId) else {
                return ConfigModelAppStatus(responseTo: request, with: .invalidModel)
            }
            model.unbind(applicationKeyWithIndex: request.applicationKeyIndex)
            return ConfigModelAppStatus(confirm: request)
            
        case let request as ConfigSIGModelAppGet:
            guard let element = localNode.element(withAddress: request.elementAddress) else {
                return ConfigSIGModelAppList(responseTo: request, with: .invalidAddress)
            }
            guard let model = element.model(withModelId: request.modelId) else {
                return ConfigSIGModelAppList(responseTo: request, with: .invalidModel)
            }
            let applicationKeys = model.boundApplicationKeys
            return ConfigSIGModelAppList(responseTo: request, with: applicationKeys)
            
        case let request as ConfigVendorModelAppGet:
            guard let element = localNode.element(withAddress: request.elementAddress) else {
                return ConfigVendorModelAppList(responseTo: request, with: .invalidAddress)
            }
            guard let model = element.model(withModelId: request.modelId) else {
                return ConfigVendorModelAppList(responseTo: request, with: .invalidModel)
            }
            let applicationKeys = model.boundApplicationKeys
            return ConfigVendorModelAppList(responseTo: request, with: applicationKeys)
                
        // Publications
        case let request as ConfigModelPublicationSet:
            guard let element = localNode.element(withAddress: request.elementAddress) else {
                return ConfigModelPublicationStatus(responseTo: request, with: .invalidAddress)
            }
            guard let model = element.model(withModelId: request.modelId) else {
                return ConfigModelPublicationStatus(responseTo: request, with: .invalidModel)
            }
            guard let _ = model.delegate?.publicationMessageComposer else {
                return ConfigModelPublicationStatus(responseTo: request, with: .invalidPublishParameters)
            }
            guard request.publish.isCancel || meshNetwork.applicationKeys[request.publish.index] != nil else {
                return ConfigModelPublicationStatus(responseTo: request, with: .invalidAppKeyIndex)
            }
            guard request.publish.isUsingMasterSecurityMaterial else {
                // Low Power feature is not supported in the library, and does not have to be.
                return ConfigModelPublicationStatus(responseTo: request, with: .featureNotSupported)
            }
            if !request.publish.isCancel {
                // A new Group?
                let address = request.publish.publicationAddress.address
                if address.isGroup && !address.isSpecialGroup &&
                   meshNetwork.group(withAddress: request.publish.publicationAddress) == nil {
                    let group = try! Group(name: NSLocalizedString("New Group", comment: ""),
                                           address: address)
                    try! meshNetwork.add(group: group)
                }
                model.set(publication: request.publish)
            } else {
                model.clearPublication()
            }
            return ConfigModelPublicationStatus(confirm: request)
            
        case let request as ConfigModelPublicationVirtualAddressSet:
            guard let element = localNode.element(withAddress: request.elementAddress) else {
                return ConfigModelPublicationStatus(responseTo: request, with: .invalidAddress)
            }
            guard let model = element.model(withModelId: request.modelId) else {
                return ConfigModelPublicationStatus(responseTo: request, with: .invalidModel)
            }
            guard let _ = model.delegate?.publicationMessageComposer else {
                return ConfigModelPublicationStatus(responseTo: request, with: .invalidPublishParameters)
            }
            guard meshNetwork.applicationKeys[request.publish.index] != nil else {
                return ConfigModelPublicationStatus(responseTo: request, with: .invalidAppKeyIndex)
            }
            guard request.publish.isUsingMasterSecurityMaterial else {
                // Low Power feature is not supported in the library, and does not have to be.
                return ConfigModelPublicationStatus(responseTo: request, with: .featureNotSupported)
            }
            // A new Group?
            if meshNetwork.group(withAddress: request.publish.publicationAddress) == nil {
                let group = try! Group(name: NSLocalizedString("New Group", comment: ""),
                                       address: request.publish.publicationAddress)
                try! meshNetwork.add(group: group)
            }
            model.set(publication: request.publish)
            return ConfigModelPublicationStatus(confirm: request)
                
        case let request as ConfigModelPublicationGet:
            guard let element = localNode.element(withAddress: request.elementAddress) else {
                return ConfigModelPublicationStatus(responseTo: request, with: .invalidAddress)
            }
            guard let model = element.model(withModelId: request.modelId) else {
                return ConfigModelPublicationStatus(responseTo: request, with: .invalidModel)
            }
            return ConfigModelPublicationStatus(responseTo: request, with: model.publish)
             
                
        // Subscriptions
        case let request as ConfigModelSubscriptionAdd:
            guard let element = localNode.element(withAddress: request.elementAddress) else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress)
            }
            guard let model = element.model(withModelId: request.modelId) else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidModel)
            }
            guard request.address.isGroup && request.address != Address.allNodes else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress)
            }
            guard model.delegate?.isSubscriptionSupported != false else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .notASubscribeModel)
            }
            do {
                let address = MeshAddress(request.address)
                // A Model can be subscribed to any Group except from All nodes.
                let group = try Group.specialGroup(withAddress: address) ??
                                meshNetwork.group(withAddress: address) ??
                                createGroup(withAddress: address)
                guard group != .allNodes else {
                    throw MeshNetworkError.invalidAddress
                }
                model.subscribe(to: group)
                return ConfigModelSubscriptionStatus(confirmAdding: group, to: model)!
            } catch {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress)
            }
            
        case let request as ConfigModelSubscriptionOverwrite:
            guard let element = localNode.element(withAddress: request.elementAddress) else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress)
            }
            guard let model = element.model(withModelId: request.modelId) else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidModel)
            }
            guard request.address.isGroup && request.address != Address.allNodes else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress)
            }
            guard model.delegate?.isSubscriptionSupported != false else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .notASubscribeModel)
            }
            do {
                let address = MeshAddress(request.address)
                // A Model can be subscribed to any Group except from All nodes.
                let group = try Group.specialGroup(withAddress: address) ??
                                meshNetwork.group(withAddress: address) ??
                                createGroup(withAddress: address)
                guard group != .allNodes else {
                    throw MeshNetworkError.invalidAddress
                }
                model.unsubscribeFromAll()
                model.subscribe(to: group)
                return ConfigModelSubscriptionStatus(confirmAdding: group, to: model)!
            } catch {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress)
            }
            
        case let request as ConfigModelSubscriptionDelete:
            guard let element = localNode.element(withAddress: request.elementAddress) else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress)
            }
            guard let model = element.model(withModelId: request.modelId) else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidModel)
            }
            guard request.address.isGroup && request.address != Address.allNodes else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress)
            }
            model.unsubscribe(from: request.address)
            return ConfigModelSubscriptionStatus(confirmDeleting: request.address, from: model)!
            
        case let request as ConfigModelSubscriptionVirtualAddressAdd:
            guard let element = localNode.element(withAddress: request.elementAddress) else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress)
            }
            guard let model = element.model(withModelId: request.modelId) else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidModel)
            }
            guard model.delegate?.isSubscriptionSupported != false else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .notASubscribeModel)
            }
            do {
                let address = MeshAddress(request.virtualLabel)
                let group = try meshNetwork.group(withAddress: address) ??
                                createGroup(withAddress: address)
                model.subscribe(to: group)
                return ConfigModelSubscriptionStatus(confirmAdding: group, to: model)!
            } catch {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress)
            }
            
        case let request as ConfigModelSubscriptionVirtualAddressOverwrite:
            guard let element = localNode.element(withAddress: request.elementAddress) else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress)
            }
            guard let model = element.model(withModelId: request.modelId) else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidModel)
            }
            guard model.delegate?.isSubscriptionSupported != false else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .notASubscribeModel)
            }
            do {
                let address = MeshAddress(request.virtualLabel)
                let group = try meshNetwork.group(withAddress: address) ??
                                createGroup(withAddress: address)
                model.unsubscribeFromAll()
                model.subscribe(to: group)
                return ConfigModelSubscriptionStatus(confirmAdding: group, to: model)!
            } catch {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress)
            }
            
        case let request as ConfigModelSubscriptionVirtualAddressDelete:
            guard let element = localNode.element(withAddress: request.elementAddress) else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress)
            }
            guard let model = element.model(withModelId: request.modelId) else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidModel)
            }
            let address = MeshAddress(request.virtualLabel)
            if let group = meshNetwork.group(withAddress: address) {
                model.unsubscribe(from: group)
            }
            return ConfigModelSubscriptionStatus(confirmDeleting: address.address, from: model)!
            
        case let request as ConfigModelSubscriptionDeleteAll:
            guard let element = localNode.element(withAddress: request.elementAddress) else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress)
            }
            guard let model = element.model(withModelId: request.modelId) else {
                return ConfigModelSubscriptionStatus(responseTo: request, with: .invalidModel)
            }
            model.unsubscribeFromAll()
            return ConfigModelSubscriptionStatus(confirmDeletingAllFrom: model)!
                
        case let request as ConfigSIGModelSubscriptionGet:
            guard let element = localNode.element(withAddress: request.elementAddress) else {
                return ConfigSIGModelSubscriptionList(responseTo: request, with: .invalidAddress)
            }
            guard let model = element.model(withModelId: request.modelId) else {
                return ConfigSIGModelSubscriptionList(responseTo: request, with: .invalidModel)
            }
            let addresses = model.subscriptions.map { $0.address.address }
            return ConfigSIGModelSubscriptionList(responseTo: request, with: addresses)
            
        case let request as ConfigVendorModelSubscriptionGet:
            guard let element = localNode.element(withAddress: request.elementAddress) else {
                return ConfigVendorModelSubscriptionList(responseTo: request, with: .invalidAddress)
            }
            guard let model = element.model(withModelId: request.modelId) else {
                return ConfigVendorModelSubscriptionList(responseTo: request, with: .invalidModel)
            }
            let addresses = model.subscriptions.map { $0.address.address }
            return ConfigVendorModelSubscriptionList(responseTo: request, with: addresses)
                
        // Default TTL
        case let request as ConfigDefaultTtlSet:
            localNode.defaultTTL = request.ttl
            fallthrough
            
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
            // TODO: Add support for sending Secure Network Beacons.
            return ConfigBeaconStatus(enabled: false)
            
        // Network Transmit settings
        case let request as ConfigNetworkTransmitSet:
            localNode.networkTransmit = Node.NetworkTransmit(request)
            fallthrough
            
        case is ConfigNetworkTransmitGet:
            return ConfigNetworkTransmitStatus(for: localNode)
            
        // Node Identity
        case let request as ConfigNodeIdentityGet:
            return ConfigNodeIdentityStatus(responseTo: request)
            
        case let request as ConfigNodeIdentitySet:
            return ConfigNodeIdentityStatus(responseTo: request)
                
        // Resetting Node
        case is ConfigNodeReset:
            return ConfigNodeResetStatus()
            
        // Heartbeat publication
        case let request as ConfigHeartbeatPublicationSet:
            // The Heartbeat Publication Destination shall be the Unassigned Address, a Unicast Address,
            // or a Group Address, all other values are Prohibited.
            guard request.destination.isUnassigned ||
                  request.destination.isUnicast ||
                  request.destination.isGroup else {
                return ConfigHeartbeatPublicationStatus(responseTo: request, with: .cannotSet)
            }
            // Network Key must be valid and known. To cancel publication any Network Key Index may be used.
            guard request.networkKeyIndex.isValidKeyIndex &&
                 (meshNetwork.networkKeys[request.networkKeyIndex] != nil || !request.enablesPublication) else {
                return ConfigHeartbeatPublicationStatus(responseTo: request, with: .invalidNetKeyIndex)
            }
            // TTL must be 0-127, PeriodLog <= 0x11 and CountLog <= 0x11 or 0xFF.
            guard request.ttl <= 0x7F &&
                  request.periodLog <= 0x11 &&
                 (request.countLog <= 0x11 || request.countLog == 0xFF) else {
                return ConfigHeartbeatPublicationStatus(responseTo: request, with: .cannotSet)
            }
            localNode.heartbeatPublication = HeartbeatPublication(request)
            fallthrough
            
        case is ConfigHeartbeatPublicationGet:
            return ConfigHeartbeatPublicationStatus(localNode.heartbeatPublication)
                
        // Heartbeat subscription
        case let request as ConfigHeartbeatSubscriptionSet:
            // The Heartbeat Subscription Source shall be the Unassigned Address or a Unicast Address,
            // all other values are Prohibited.
            guard request.source.isUnassigned ||
                  request.source.isUnicast else {
                return ConfigHeartbeatSubscriptionStatus(responseTo: request, with: .cannotSet)
            }
            // The Heartbeat Subscription Destination shall be the Unassigned Address, the primary
            // Unicast Address of the local Node, or a Group Address, all other values are Prohibited.
            guard request.destination.isUnassigned ||
                  request.destination.isGroup ||
                  request.destination == localNode.primaryUnicastAddress else {
                return ConfigHeartbeatSubscriptionStatus(responseTo: request, with: .cannotSet)
            }
            // Values 0x12-0xFF are Prohibited.
            guard request.periodLog <= 0x11 else {
                return ConfigHeartbeatSubscriptionStatus(responseTo: request, with: .cannotSet)
            }
            // If the Set message disables active Heartbeat subscription,
            // the returned Status should contain the last Min Hops, Max Hops and CountLog.
            if !request.enablesSubscription,
               let currentSubscription = localNode.heartbeatSubscription {
                localNode.heartbeatSubscription = nil
                return ConfigHeartbeatSubscriptionStatus(cancel: currentSubscription)
            }
               
            localNode.heartbeatSubscription = HeartbeatSubscription(request)
            fallthrough
            
        case is ConfigHeartbeatSubscriptionGet:
            return ConfigHeartbeatSubscriptionStatus(localNode.heartbeatSubscription)
            
        case let request as ConfigKeyRefreshPhaseGet:
            // If there is no such key, return .invalidNetKeyIndex.
            guard let networkKey = meshNetwork.networkKeys[request.networkKeyIndex] else {
                return ConfigKeyRefreshPhaseStatus(responseTo: request, with: .invalidNetKeyIndex)
            }
            return ConfigKeyRefreshPhaseStatus(reportPhaseOf: networkKey)
            
        case let request as ConfigKeyRefreshPhaseSet:
            // If there is no such key, return .invalidNetKeyIndex.
            guard let networkKey = meshNetwork.networkKeys[request.networkKeyIndex] else {
                return ConfigKeyRefreshPhaseStatus(responseTo: request, with: .invalidNetKeyIndex)
            }
            // Check all possible transitions.
            switch (networkKey.phase, request.transition) {
            // It is not possible to transition from Phase 0 (Normal Operation) to
            // Phase 2 (Using New Keys).
            case (.normalOperation, .useNewKeys):
                return ConfigKeyRefreshPhaseStatus(responseTo: request, with: .cannotSet)
            // Transitioning from Phase 1 (Distributing Keys) sets the phase to .usingNewKeys.
            case (.keyDistribution, .useNewKeys):
                networkKey.phase = .usingNewKeys // This updates the modification Date.
            // If we already were in Phase 2, no action is needed.
            case (.usingNewKeys, .useNewKeys):
                break
                
            // Transitioning from Phase 0 to Phase 0 is a NO OP.
            case (.normalOperation, .revokeOldKeys):
                break
            // For the remaining transitions we need to invalidate old keys.
            case (_, .revokeOldKeys):
                 // Revoke the old Network Key...
                 networkKey.oldKey = nil // This will set the phase to .normalOperation.
                 // ...and old Application Keys bound to it.
                 meshNetwork.applicationKeys.boundTo(networkKey)
                     .forEach { $0.oldKey = nil }
            }
            return ConfigKeyRefreshPhaseStatus(reportPhaseOf: networkKey)
        
        case let request as ConfigLowPowerNodePollTimeoutGet:
            // The library does not support Friend feature.
            // The below code will reply with PollTimeout set to 0x000000.
            return ConfigLowPowerNodePollTimeoutStatus(responseTo: request)
            
        default:
            fatalError("Message not handled: \(request)")
        }
    }
    
    func model(_ model: Model, didReceiveUnacknowledgedMessage message: UnacknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) {
        switch message {
            
        default:
            fatalError("Message not supported: \(message)")
        }
    }
    
    func model(_ model: Model, didReceiveResponse response: MeshResponse,
               toAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address) {
        switch response {
            
        default:
            fatalError("Message not supported: \(response)")
        }
    }
        
}

private extension ConfigurationServerHandler {
    
    private func createGroup(withAddress address: MeshAddress) throws -> Group {
        let group = try Group(name: NSLocalizedString("New Group", comment: ""),
                              address: address)
        try meshNetwork.add(group: group)
        return group
    }
    
}


