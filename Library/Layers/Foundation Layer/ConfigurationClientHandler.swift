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

internal class ConfigurationClientHandler: ModelDelegate {
    weak var meshNetwork: MeshNetwork!
    
    let messageTypes: [UInt32 : MeshMessage.Type]
    let isSubscriptionSupported: Bool = false
    let publicationMessageComposer: MessageComposer? = nil
    
    init(_ meshNetwork: MeshNetwork) {
        let types: [ConfigMessage.Type] = [
            ConfigCompositionDataStatus.self,
            ConfigNetKeyStatus.self,
            ConfigNetKeyList.self,
            ConfigAppKeyStatus.self,
            ConfigAppKeyList.self,
            ConfigModelAppStatus.self,
            ConfigSIGModelAppList.self,
            ConfigVendorModelAppList.self,
            ConfigModelPublicationStatus.self,
            ConfigModelSubscriptionStatus.self,
            ConfigSIGModelSubscriptionList.self,
            ConfigVendorModelSubscriptionList.self,
            ConfigDefaultTtlStatus.self,
            ConfigRelayStatus.self,
            ConfigGATTProxyStatus.self,
            ConfigFriendStatus.self,
            ConfigBeaconStatus.self,
            ConfigNetworkTransmitStatus.self,
            ConfigNodeIdentityStatus.self,
            ConfigNodeResetStatus.self,
            ConfigHeartbeatPublicationStatus.self,
            ConfigHeartbeatSubscriptionStatus.self,
            ConfigKeyRefreshPhaseStatus.self,
            ConfigLowPowerNodePollTimeoutStatus.self,
        ]
        self.meshNetwork = meshNetwork
        self.messageTypes = types.toMap()
    }
    
    func model(_ model: Model, didReceiveAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) -> MeshResponse {
        switch request {
            
        default:
            fatalError("Message not supported: \(request)")
        }
    }
    
    func model(_ model: Model, didReceiveUnacknowledgedMessage message: UnacknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) {
        switch message {
            
        default:
            // Ignore.
            break
        }
    }
    
    func model(_ model: Model, didReceiveResponse response: MeshResponse,
               toAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address) {
        switch response {

        // Composition Data
        case let compositionData as ConfigCompositionDataStatus:
            // Do not override your own elements.
            guard meshNetwork.localProvisioner?.primaryUnicastAddress != source else {
                break
            }
            if let node = meshNetwork.node(withAddress: source) {
                node.apply(compositionData: compositionData)
            }

        // Network Keys Management
        case let netKeyStatus as ConfigNetKeyStatus:
            if netKeyStatus.isSuccess,
               let node = meshNetwork.node(withAddress: source) {
                switch request {
                case is ConfigNetKeyAdd:
                    node.add(networkKeyWithIndex: netKeyStatus.networkKeyIndex)
                case is ConfigNetKeyUpdate:
                    node.update(networkKeyWithIndex: netKeyStatus.networkKeyIndex)
                case is ConfigNetKeyDelete:
                    node.remove(networkKeyWithIndex: netKeyStatus.networkKeyIndex)
                default:
                    break
                }
            }
                
        case let list as ConfigNetKeyList:
            if let node = meshNetwork.node(withAddress: source) {
                node.set(networkKeysWithIndexes: list.networkKeyIndexes)
            }

        // Application Key Management
        case let appKeyStatus as ConfigAppKeyStatus:
            if appKeyStatus.isSuccess,
               let node = meshNetwork.node(withAddress: source) {
                switch request {
                case is ConfigAppKeyAdd:
                    node.add(applicationKeyWithIndex: appKeyStatus.applicationKeyIndex)
                case is ConfigAppKeyUpdate:
                    node.update(applicationKeyWithIndex: appKeyStatus.applicationKeyIndex)
                case is ConfigAppKeyDelete:
                    node.remove(applicationKeyWithIndex: appKeyStatus.applicationKeyIndex)
                default:
                    break
                }
            }
                
        case let list as ConfigAppKeyList:
            if let node = meshNetwork.node(withAddress: source) {
                node.set(applicationKeysWithIndexes: list.applicationKeyIndexes,
                         forNetworkKeyWithIndex: list.networkKeyIndex)
            }
            
        // Model Bindings
        case let status as ConfigModelAppStatus:
            if status.isSuccess,
               let node = meshNetwork.node(withAddress: source),
               let element = node.element(withAddress: status.elementAddress),
               let model = element.model(withModelId: status.modelId) {
                switch request {
                case is ConfigModelAppBind:
                    model.bind(applicationKeyWithIndex: status.applicationKeyIndex)
                case is ConfigModelAppUnbind:
                    model.unbind(applicationKeyWithIndex: status.applicationKeyIndex)
                default:
                    break
                }
            }
                
        case let list as ConfigModelAppList & StatusMessage:
            if list.isSuccess,
               let node = meshNetwork.node(withAddress: source),
               let element = node.element(withAddress: list.elementAddress),
               let model = element.model(withModelId: list.modelId) {
                model.set(boundApplicationKeysWithIndexes: list.applicationKeyIndexes)
            }
            
        // Publications
        case let status as ConfigModelPublicationStatus:
            if status.isSuccess,
               let node = meshNetwork.node(withAddress: source),
               let element = node.element(withAddress: status.elementAddress),
               let model = element.model(withModelId: status.modelId) {
                switch request {
                case is ConfigModelPublicationSet:
                    if !status.publish.isCancel {
                        model.set(publication: status.publish)
                    } else {
                        // An unassigned Address is sent to remove the publication.
                        model.clearPublication()
                    }
                case let request as ConfigModelPublicationVirtualAddressSet:
                    // Note: The Publish from the request has the Virtual Label set,
                    //       while the status has only the 16-bit Virtual Address.
                    // Note: We assume here, that the response is identical to the
                    //       request, with an exception of the Virtual Label.
                    model.set(publication: request.publish) /* NOT status.publish */
                case is ConfigModelPublicationGet:
                    let publicationAddress = status.publish.publicationAddress
                    if publicationAddress.address.isUnassigned {
                        model.clearPublication()
                    } else if publicationAddress.address.isVirtual {
                        // The received status message is missing the Virtual Label.
                        // Let's try to find it in the local groups.
                        if let group = meshNetwork.group(withAddress: publicationAddress),
                            let _ = group.address.virtualLabel {
                            // A Group with the same address and non-nil Virtual Label has been found.
                            model.set(publication: status.publish.withAddress(address: group.address))
                        } else {
                            // The Model is publishing to an unknown Virtual Label.
                            // The label will remain `nil`, but it's virtual address is known.
                            model.set(publication: status.publish)
                        }
                    } else {
                        model.set(publication: status.publish)
                    }
                default:
                    break
                }
            }
        
        // Subscriptions
        case let status as ConfigModelSubscriptionStatus:
            if status.isSuccess,
               let node = meshNetwork.node(withAddress: source),
               let element = node.element(withAddress: status.elementAddress),
               let model = element.model(withModelId: status.modelId) {
                // When a Subscription List is modified on a Node, it affects all
                // Models with bound state on the same Element.
                let models = [model] + model.relatedModels
                    .filter { $0.parentElement == model.parentElement }
                // The status for Delete All request has an invalid address.
                // Handle it differently here.
                if let _ = request as? ConfigModelSubscriptionDeleteAll {
                    models.forEach { $0.unsubscribeFromAll() }
                    break
                }
                // Here it should be safe to search for the group.
                let address = MeshAddress(status.address)
                guard let group = Group.specialGroup(withAddress: address) ??
                                  meshNetwork.group(withAddress: address),
                          group != .allNodes else {
                    break
                }
                switch request {
                case is ConfigModelSubscriptionOverwrite, is ConfigModelSubscriptionVirtualAddressOverwrite:
                    models.forEach { $0.unsubscribeFromAll() }
                    fallthrough
                case is ConfigModelSubscriptionAdd, is ConfigModelSubscriptionVirtualAddressAdd:
                    models.forEach { $0.subscribe(to: group) }
                case is ConfigModelSubscriptionDelete, is ConfigModelSubscriptionVirtualAddressDelete:
                    models.forEach { $0.unsubscribe(from: group) }
                default:
                    break
                }
            }
                
        case let list as ConfigModelSubscriptionList & StatusMessage:
            if list.isSuccess,
               let node = meshNetwork.node(withAddress: source),
               let element = node.element(withAddress: list.elementAddress),
               let model = element.model(withModelId: list.modelId) {
                // When a Subscription List is modified on a Node, it affects all
                // Models with bound state on the same Element.
                let models = [model] + model.relatedModels
                    .filter { $0.parentElement == model.parentElement }
                // A new list will be set. Remove existing items.
                models.forEach { $0.unsubscribeFromAll() }
                // For each new address...
                for address in list.addresses {
                    // ...look for an existing Group.
                    if let group = Group.specialGroup(withAddress: address) ??
                                   meshNetwork.group(withAddress: address) {
                        // When found, and the Group isn't "all Nodes"...
                        if group != .allNodes {
                            // ...subscribe all models to it.
                            models.forEach { $0.subscribe(to: group) }
                        }
                    } else {
                        // When the Group was not found, but it is a regular one, not a Virtual Group,...
                        if address.isGroup && !address.isSpecialGroup {
                            do {
                                // ...create a New Group with default name.
                                let group = try Group(name: NSLocalizedString("New Group", comment: ""),
                                                      address: MeshAddress(address))
                                // Add the Group to the Network and subscribe the Models.
                                try meshNetwork.add(group: group)
                                models.forEach { $0.subscribe(to: group) }
                            } catch {
                                // This should never happen.
                                continue
                            }
                        } else {
                            // Unknown Virtual Group, or a special group.
                            // The Virtual Label is unknown, so we can't create it here.
                            continue
                        }
                    }
                }
            }

        // Default TTL
        case let defaultTtl as ConfigDefaultTtlStatus:
            if let node = meshNetwork.node(withAddress: source) {
                node.ttl = defaultTtl.ttl
            }
                
        // Relay settings
        case let status as ConfigRelayStatus:
            if let node = meshNetwork.node(withAddress: source) {
                node.ensureFeatures.relay = status.state
                if case .notSupported = status.state {
                    node.relayRetransmit = nil
                } else {
                    node.relayRetransmit = Node.RelayRetransmit(status)
                }
            }

        // GATT Proxy settings
        case let status as ConfigGATTProxyStatus:
            if let node = meshNetwork.node(withAddress: source) {
                node.ensureFeatures.proxy = status.state
            }
            
        // Friend settings
        case let status as ConfigFriendStatus:
            if let node = meshNetwork.node(withAddress: source) {
                node.ensureFeatures.friend = status.state
            }
                
        // Secure Network Beacon configuration
        case let status as ConfigBeaconStatus:
            if let node = meshNetwork.node(withAddress: source) {
                node.secureNetworkBeacon = status.isEnabled
            }

        // Network Transmit settings
        case let status as ConfigNetworkTransmitStatus:
            if let node = meshNetwork.node(withAddress: source) {
                node.networkTransmit = Node.NetworkTransmit(status)
            }
            
        // Reset
        case is ConfigNodeResetStatus:
            if let node = meshNetwork.node(withAddress: source) {
                meshNetwork.remove(node: node)
            }
            
        // Heartbeat publication
        case let status as ConfigHeartbeatPublicationStatus:
            if let node = meshNetwork.node(withAddress: source),
               !node.isLocalProvisioner {
                // This may be set to nil.
                node.heartbeatPublication = HeartbeatPublication(status)
            }
                
        // Heartbeat subscription
        case let status as ConfigHeartbeatSubscriptionStatus:
            if let node = meshNetwork.node(withAddress: source),
               !node.isLocalProvisioner {
                // This may be set to nil.
                node.heartbeatSubscription = HeartbeatSubscription(status)
            }
            
        // Node Identity
        case is ConfigNodeIdentityStatus:
            // Do nothing. The model does not need to be updated.
            break
            
        case is ConfigKeyRefreshPhaseStatus:
            // Do nothing. The model does not need to be updated.
            break
            
        case is ConfigLowPowerNodePollTimeoutStatus:
            // Do nothing. The model does not need to be updated.
            break
            
        default:
            break
        }
    }
        
}
