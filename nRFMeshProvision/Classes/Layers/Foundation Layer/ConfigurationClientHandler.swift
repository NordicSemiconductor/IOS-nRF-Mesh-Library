//
//  ConfigurationClientHandler.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 30/09/2019.
//

import Foundation

internal class ConfigurationClientHandler: ModelDelegate {
    weak var meshNetwork: MeshNetwork!
    
    let messageTypes: [UInt32 : MeshMessage.Type]
    let isSubscriptionSupported: Bool = false
    
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
            ConfigNodeResetStatus.self
        ]
        self.meshNetwork = meshNetwork
        self.messageTypes = types.toMap()
    }
    
    func model(_ model: Model, didReceiveAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) -> MeshMessage {
        switch request {
            
        default:
            fatalError("Message not supported: \(request)")
        }
    }
    
    func model(_ model: Model, didReceiveUnacknowledgedMessage message: MeshMessage,
               from source: Address, sentTo destination: MeshAddress) {
        switch message {
            
        default:
            // Ignore.
            break
        }
    }
    
    func model(_ model: Model, didReceiveResponse response: MeshMessage,
               toAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address) {
        switch response {

        // Composition Data
        case let compositionData as ConfigCompositionDataStatus:
            // Do not override your own elements.
            guard meshNetwork.localProvisioner?.unicastAddress != source else {
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
                
        case let list as ConfigModelAppList:
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
                let address = MeshAddress(status.address)
                
                // The status for Delete All request has an invalid address.
                // Handle it differently here.
                if let _ = request as? ConfigModelSubscriptionDeleteAll {
                    model.unsubscribeFromAll()
                    break
                }
                // Here it should be safe to search for the group.
                guard let group = meshNetwork.group(withAddress: address) else {
                    break
                }
                switch request {
                case is ConfigModelSubscriptionOverwrite, is ConfigModelSubscriptionVirtualAddressOverwrite:
                    model.unsubscribeFromAll()
                    fallthrough
                case is ConfigModelSubscriptionAdd, is ConfigModelSubscriptionVirtualAddressAdd:
                    model.subscribe(to: group)
                case is ConfigModelSubscriptionDelete, is ConfigModelSubscriptionVirtualAddressDelete:
                    model.unsubscribe(from: group)
                default:
                    break
                }
            }
                
        case let list as ConfigModelSubscriptionList:
            if list.isSuccess,
               let node = meshNetwork.node(withAddress: source),
               let element = node.element(withAddress: list.elementAddress),
               let model = element.model(withModelId: list.modelId) {
                model.unsubscribeFromAll()
                for address in list.addresses {
                    if let group = meshNetwork.groups.first(where: { $0.address.address == address }) {
                        model.subscribe(to: group)
                    } else {
                        if address.isGroup && !address.isSpecialGroup {
                            do {
                                let group = try Group(name: NSLocalizedString("New Group", comment: ""),
                                                      address: MeshAddress(address))
                                try meshNetwork.add(group: group)
                                model.subscribe(to: group)
                            } catch {
                                // This should never happen.
                                continue
                            }
                        } else {
                            // Unknown Virtual Group. The Virtual Label is unknown,
                            // so we can't create it here.
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
            
        default:
            break
        }
    }
        
}
