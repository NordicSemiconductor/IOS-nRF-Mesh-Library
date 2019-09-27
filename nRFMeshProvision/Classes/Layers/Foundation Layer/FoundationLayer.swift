//
//  FoundationLayer.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 01/07/2019.
//

import Foundation

internal class FoundationLayer {
    let networkManager: NetworkManager
    
    var requests: [Address : ConfigMessage]
    
    init(_ networkManager: NetworkManager) {
        self.networkManager = networkManager
        self.requests = [:]
    }
    
    /// This method handles the received Config Message, depending on its type.
    ///
    /// - parameter configMessage: The Mesh Message received.
    /// - parameter source:        The Unicast Address of the Node that has sent the
    ///                            message.
    /// - parameter destination:   The destination address of the message.
    /// - parameter keySet:        The set of keys that the message was encrypted with.
    func handle(configMessage: ConfigMessage,
                sentFrom source: Address, to destination: Address,
                with keySet: KeySet) {
        guard let meshNetwork = networkManager.meshNetwork,
              let localNode = meshNetwork.localProvisioner?.node else {
            return
        }
        // Ignore messages sent to another Nodes.
        guard destination == localNode.unicastAddress else {
            return
        }
        
        switch configMessage {
            
        // Composition Data
        case is ConfigCompositionDataGet:
            let compositionData = Page0(node: localNode)
            networkManager.reply(toMessageSentTo: destination,
                                 with: ConfigCompositionDataStatus(report: compositionData),
                                 to: source, using: keySet)
            
        case let compositionData as ConfigCompositionDataStatus:
            if let node = meshNetwork.node(withAddress: source) {
                node.apply(compositionData: compositionData)
                save()
            }

        // Network Keys Management
        case let request as ConfigNetKeyAdd:
            let keyIndex = request.networkKeyIndex
            do {
                // Make sure the key with given index didn't exist or was identical to the
                // one in the request. Otherwise, return .keyIndexAlreadyStored.
                var networkKey = meshNetwork.networkKeys[keyIndex]
                guard networkKey == nil || networkKey!.key == request.key else {
                    networkManager.reply(toMessageSentTo: destination,
                                         with: ConfigNetKeyStatus(responseTo: request, with: .keyIndexAlreadyStored),
                                         to: source, using: keySet)
                    break
                }
                if networkKey == nil {
                    networkKey = try meshNetwork.add(networkKey: request.key, withIndex: keyIndex,
                                                     name: "Network Key \(keyIndex + 1)")
                }
                // Add the Network Key index to the local Node.
                if let node = meshNetwork.localProvisioner?.node {
                    node.add(networkKeyWithIndex: keyIndex)
                }
                save()
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigNetKeyStatus(confirm: networkKey!),
                                     to: source, using: keySet)
            } catch {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigNetKeyStatus(responseTo: request, with: .unspecifiedError),
                                     to: source, using: keySet)
            }
            
        case let request as ConfigNetKeyUpdate:
            let keyIndex = request.networkKeyIndex
            // If there is no such key, return .invalidNetKeyIndex.
            guard let networkKey = meshNetwork.networkKeys[keyIndex] else {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigNetKeyStatus(responseTo: request, with: .invalidNetKeyIndex),
                                     to: source, using: keySet)
                break
            }
            // Update the key data (observer will set the `oldKey` automatically).
            networkKey.key = request.key
            // And mark the key in the local Node as updated.
            if let node = meshNetwork.localProvisioner?.node {
                node.update(networkKeyWithIndex: keyIndex)
            }
            save()
            networkManager.reply(toMessageSentTo: destination,
                                 with: ConfigNetKeyStatus(confirm: networkKey),
                                 to: source, using: keySet)
            
        case let request as ConfigNetKeyDelete:
            let keyIndex = request.networkKeyIndex
            // Force delete the key from the global configuration.
            try? meshNetwork.remove(networkKeyWithKeyIndex: keyIndex, force: true)
            // Remove the key also from the local Node. This will also remove all
            // Application Keys bound to it.
            if let node = meshNetwork.localProvisioner?.node {
                node.remove(networkKeyWithIndex: keyIndex)
            }
            save()
            networkManager.reply(toMessageSentTo: destination,
                                 with: ConfigNetKeyStatus(responseTo: request, with: .success),
                                 to: source, using: keySet)
            
        case let netKeyStatus as ConfigNetKeyStatus:
            if netKeyStatus.isSuccess, let node = meshNetwork.node(withAddress: source) {
                switch requests[source] {
                case is ConfigNetKeyAdd:
                    guard node.netKeys[netKeyStatus.networkKeyIndex] == nil else {
                        break
                    }
                    node.netKeys.append(Node.NodeKey(index: netKeyStatus.networkKeyIndex, updated: false))
                    save()
                    requests.removeValue(forKey: source)
                case is ConfigNetKeyUpdate:
                    guard let netKey = node.netKeys[netKeyStatus.networkKeyIndex] else {
                        break
                    }
                    netKey.updated = true
                    save()
                    requests.removeValue(forKey: source)
                case is ConfigNetKeyDelete:
                    node.remove(networkKeyWithIndex: netKeyStatus.networkKeyIndex)
                    save()
                    requests.removeValue(forKey: source)
                default:
                    break
                }
            }
            
        case is ConfigNetKeyGet:
            networkManager.reply(toMessageSentTo: destination,
                                 with: ConfigNetKeyList(networkKeys: meshNetwork.networkKeys),
                                 to: source, using: keySet)
            
        case let list as ConfigNetKeyList:
            if let node = meshNetwork.node(withAddress: source) {
                node.netKeys = list.networkKeyIndexs
                    .map({ Node.NodeKey(index: $0, updated: false) })
                    .sorted()
                save()
            }
            
        // Application Key Management
        case let request as ConfigAppKeyAdd:
            let networkKeyIndex = request.networkKeyIndex
            let keyIndex = request.applicationKeyIndex
            // If the Network Key does not exist, return .invalidNetKeyIndex.
            guard let _ = meshNetwork.networkKeys[networkKeyIndex] else {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigAppKeyStatus(responseTo: request, with: .invalidNetKeyIndex),
                                     to: source, using: keySet)
                break
            }
            do {
                // Make sure the key with given index didn't exist or was identical to the
                // one in the request. Otherwise, return .keyIndexAlreadyStored.
                var applicationKey = meshNetwork.applicationKeys[keyIndex]
                guard applicationKey == nil ||
                      (applicationKey!.key == request.key &&
                      applicationKey!.boundNetworkKeyIndex == networkKeyIndex) else {
                        networkManager.reply(toMessageSentTo: destination,
                                             with: ConfigAppKeyStatus(responseTo: request, with: .keyIndexAlreadyStored),
                                             to: source, using: keySet)
                    break
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
                save()
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigAppKeyStatus(confirm: applicationKey!),
                                     to: source, using: keySet)
            } catch {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigAppKeyStatus(responseTo: request, with: .unspecifiedError),
                                     to: source, using: keySet)
            }
            
        case let request as ConfigAppKeyUpdate:
            let networkKeyIndex = request.networkKeyIndex
            let keyIndex = request.applicationKeyIndex
            // If the Network Key does not exist, return .invalidNetKeyIndex.
            guard let _ = meshNetwork.networkKeys[networkKeyIndex] else {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigAppKeyStatus(responseTo: request, with: .invalidNetKeyIndex),
                                     to: source, using: keySet)
                break
            }
            // If the Application key does not exist, return .invalidAppKeyIndex.
            guard let applicationKey = meshNetwork.applicationKeys[keyIndex] else {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigAppKeyStatus(responseTo: request, with: .invalidAppKeyIndex),
                                     to: source, using: keySet)
                break
            }
            // If the binding is incorrect, return .invalidBinding.
            guard applicationKey.boundNetworkKeyIndex == networkKeyIndex else {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigAppKeyStatus(responseTo: request, with: .invalidBinding),
                                     to: source, using: keySet)
                break
            }
            // Update the key data (observer will set the `oldKey` automatically).
            applicationKey.key = request.key
            // And mark the key in the local Node as updated.
            if let node = meshNetwork.localProvisioner?.node {
                node.update(applicationKeyWithIndex: keyIndex)
            }
            save()
            networkManager.reply(toMessageSentTo: destination,
                                 with: ConfigAppKeyStatus(confirm: applicationKey),
                                 to: source, using: keySet)
            
        case let request as ConfigAppKeyDelete:
            let networkKeyIndex = request.networkKeyIndex
            let keyIndex = request.applicationKeyIndex
            // If the Network Key does not exist, return .invalidNetKeyIndex.
            guard let _ = meshNetwork.networkKeys[networkKeyIndex] else {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigAppKeyStatus(responseTo: request, with: .invalidNetKeyIndex),
                                     to: source, using: keySet)
                break
            }
            // Force delete the key from the global configuration.
            try? meshNetwork.remove(applicationKeyWithKeyIndex: keyIndex, force: true)
            // Remove the key also from the local Node. This will also remove all
            // Application Keys bound to it.
            if let node = meshNetwork.localProvisioner?.node {
                node.remove(applicationKeyWithIndex: keyIndex)
            }
            save()
            networkManager.reply(toMessageSentTo: destination,
                                 with: ConfigAppKeyStatus(responseTo: request, with: .success),
                                 to: source, using: keySet)
        
        case let appKeyStatus as ConfigAppKeyStatus:
            if appKeyStatus.isSuccess, let node = meshNetwork.node(withAddress: source) {
                switch requests[source] {
                case is ConfigAppKeyAdd:
                    guard node.appKeys[appKeyStatus.applicationKeyIndex] == nil else {
                        break
                    }
                    node.appKeys.append(Node.NodeKey(index: appKeyStatus.applicationKeyIndex, updated: false))
                    save()
                    requests.removeValue(forKey: source)
                case is ConfigAppKeyUpdate:
                    guard let appKey = node.appKeys[appKeyStatus.applicationKeyIndex] else {
                        break
                    }
                    appKey.updated = true
                    save()
                    requests.removeValue(forKey: source)
                case is ConfigAppKeyDelete:
                    node.remove(applicationKeyWithIndex: appKeyStatus.applicationKeyIndex)
                    save()
                    requests.removeValue(forKey: source)
                default:
                    break
                }
            }
            
        case let request as ConfigAppKeyGet:
            let networkKeyIndex = request.networkKeyIndex
            // If the Network Key does not exist, return .invalidNetKeyIndex.
            guard let _ = meshNetwork.networkKeys[networkKeyIndex] else {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigAppKeyList(responseTo: request, with: .invalidNetKeyIndex),
                                     to: source, using: keySet)
                break
            }
            let boundAppKeys = meshNetwork.applicationKeys.filter {
                $0.boundNetworkKeyIndex == networkKeyIndex
            }
            networkManager.reply(toMessageSentTo: destination,
                                 with: ConfigAppKeyList(responseTo: request, with: boundAppKeys),
                                 to: source, using: keySet)
            
        case let list as ConfigAppKeyList:
            if let node = meshNetwork.node(withAddress: source) {
                // Leave only those App Keys, that are bound to a different Network Key than in the
                // received response.
                node.appKeys = node.appKeys.filter {
                    node.applicationKeys[$0.index]?.boundNetworkKeyIndex != list.networkKeyIndex
                }
                node.appKeys.append(contentsOf: list.applicationKeyIndexes.map({ Node.NodeKey(index: $0, updated: false) }))
                node.appKeys.sort()
                save()
            }
            
        // Model Bindings
        case let request as ConfigModelAppBind:
            if let element = localNode.element(withAddress: destination),
               let model = element.model(withModelId: request.modelId) {
                model.bind(applicationKeyWithIndex: request.applicationKeyIndex)
                save()
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelAppStatus(confirm: request),
                                     to: source, using: keySet)
            } else {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelAppStatus(responseTo: request, with: .invalidModel),
                                     to: source, using: keySet)
            }
            
        case let request as ConfigModelAppUnbind:
            if let element = localNode.element(withAddress: destination),
               let model = element.model(withModelId: request.modelId) {
                model.unbind(applicationKeyWithIndex: request.applicationKeyIndex)
                save()
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelAppStatus(confirm: request),
                                     to: source, using: keySet)
            } else {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelAppStatus(responseTo: request, with: .invalidModel),
                                     to: source, using: keySet)
            }
            
        case let status as ConfigModelAppStatus:
            if status.isSuccess,
                let node = meshNetwork.node(withAddress: source),
                let element = node.element(withAddress: status.elementAddress),
                let model = element.model(withModelId: status.modelId) {
                switch requests[source] {
                case is ConfigModelAppBind:
                    model.bind(applicationKeyWithIndex: status.applicationKeyIndex)
                    save()
                    requests.removeValue(forKey: source)
                case is ConfigModelAppUnbind:
                    model.unbind(applicationKeyWithIndex: status.applicationKeyIndex)
                    save()
                    requests.removeValue(forKey: source)
                default:
                    break
                }
            }
        
        case let request as ConfigSIGModelAppGet:
            if let element = localNode.element(withAddress: destination) {
                if let model = element.model(withModelId: request.modelId) {
                    let applicationKeys = model.boundApplicationKeys
                    networkManager.reply(toMessageSentTo: destination,
                                         with: ConfigSIGModelAppList(responseTo: request, with: applicationKeys),
                                         to: source, using: keySet)
                } else {
                    networkManager.reply(toMessageSentTo: destination,
                                         with: ConfigSIGModelAppList(responseTo: request, with: .invalidModel),
                                         to: source, using: keySet)
                }
            }
            
        case let request as ConfigVendorModelAppGet:
            if let element = localNode.element(withAddress: destination),
               let model = element.model(withModelId: request.modelId) {
               let applicationKeys = model.boundApplicationKeys
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigVendorModelAppList(responseTo: request, with: applicationKeys),
                                     to: source, using: keySet)
            } else {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigVendorModelAppList(responseTo: request, with: .invalidModel),
                                     to: source, using: keySet)
            }
            
        case let list as ConfigModelAppList:
            if list.isSuccess,
                let node = meshNetwork.node(withAddress: source),
                let element = node.element(withAddress: list.elementAddress),
                let model = element.model(withModelId: list.modelId) {
                // Replace the known binding with what was received in the message.
                model.bind = list.applicationKeyIndexes.sorted()
                save()
            }
            
        // Publications
        case let request as ConfigModelPublicationSet:
            if let element = localNode.element(withAddress: destination),
               let model = element.model(withModelId: request.modelId) {
                // Validate request.
                guard request.publish.isCancel || meshNetwork.applicationKeys[request.publish.index] != nil else {
                    networkManager.reply(toMessageSentTo: destination,
                                         with: ConfigModelPublicationStatus(responseTo: request, with: .invalidPublishParameters),
                                         to: source, using: keySet)
                    break
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
                save()
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelPublicationStatus(confirm: request),
                                     to: source, using: keySet)
            } else {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelPublicationStatus(responseTo: request, with: .invalidModel),
                                     to: source, using: keySet)
            }
            
        case let request as ConfigModelPublicationVirtualAddressSet:
            if let element = localNode.element(withAddress: destination),
                let model = element.model(withModelId: request.modelId) {
                // Validate request.
                guard meshNetwork.applicationKeys[request.publish.index] != nil else {
                    networkManager.reply(toMessageSentTo: destination,
                                         with: ConfigModelPublicationStatus(responseTo: request, with: .invalidPublishParameters),
                                         to: source, using: keySet)
                    break
                }
                // A new Group?
                if meshNetwork.group(withAddress: request.publish.publicationAddress) == nil {
                    let group = try! Group(name: "New Group", address: request.publish.publicationAddress)
                    try! meshNetwork.add(group: group)
                }
                model.publish = request.publish
                save()
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelPublicationStatus(confirm: request),
                                     to: source, using: keySet)
            } else {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelPublicationStatus(responseTo: request, with: .invalidModel),
                                     to: source, using: keySet)
            }
            
        case let request as ConfigModelPublicationGet:
            if let element = localNode.element(withAddress: destination),
               let model = element.model(withModelId: request.modelId) {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelPublicationStatus(responseTo: request, with: model.publish),
                                     to: source, using: keySet)
            } else {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelPublicationStatus(responseTo: request, with: .invalidModel),
                                     to: source, using: keySet)
            }
            
        case let status as ConfigModelPublicationStatus:
            if status.isSuccess,
                let node = meshNetwork.node(withAddress: source),
                let element = node.element(withAddress: status.elementAddress),
                let model = element.model(withModelId: status.modelId) {
                switch requests[source] {
                case is ConfigModelPublicationSet:
                    if !status.publish.isCancel {
                        model.publish = status.publish
                    } else {
                        // An unassigned Address is sent to remove the publication.
                        model.publish = nil
                    }
                    save()
                    requests.removeValue(forKey: source)
                case let request as ConfigModelPublicationVirtualAddressSet:
                    // Note: The Publish from the request has the Virtual Label set,
                    //       while the status has only the 16-bit Virtual Address.
                    // Note: We assume here, that the response is identical to the
                    //       request, with an exception of the Virtual Label.
                    model.publish = request.publish /* NOT status.publish */
                    save()
                    requests.removeValue(forKey: source)
                case is ConfigModelPublicationGet:
                    let publicationAddress = status.publish.publicationAddress
                    if publicationAddress.address.isUnassigned {
                        model.publish = nil
                    } else if publicationAddress.address.isVirtual {
                        // The received status message is missing the Virtual Label.
                        // Let's try to find it in the local groups.
                        if let group = meshNetwork.group(withAddress: publicationAddress),
                            let _ = group.address.virtualLabel {
                            // A Group with the same address and non-nil Virtual Label has been found.
                            model.publish = status.publish.withAddress(address: group.address)
                        } else {
                            // The Model is publishing to an unknown Virtual Label.
                            // The label will remain `nil`, but it's virtual address is known.
                            model.publish = status.publish
                        }
                    } else {
                        model.publish = status.publish
                    }
                    save()
                    requests.removeValue(forKey: source)
                default:
                    break
                }
            }
            
        // Subscriptions
        case let request as ConfigModelSubscriptionAdd:
            if let element = localNode.element(withAddress: destination),
               let model = element.model(withModelId: request.modelId) {
                guard request.address.isGroup && request.address != Address.allNodes else {
                    networkManager.reply(toMessageSentTo: destination,
                                         with: ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress),
                                         to: source, using: keySet)
                    break
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
                        networkManager.reply(toMessageSentTo: destination,
                                             with: ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress),
                                             to: source, using: keySet)
                        break
                    }
                }
                save()
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelSubscriptionStatus(confirmAdding: group!, to: model),
                                     to: source, using: keySet)
            } else {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelSubscriptionStatus(responseTo: request, with: .invalidModel),
                                     to: source, using: keySet)
            }
            
        case let request as ConfigModelSubscriptionOverwrite:
            if let element = localNode.element(withAddress: destination),
               let model = element.model(withModelId: request.modelId) {
                guard request.address.isGroup && request.address != Address.allNodes else {
                    networkManager.reply(toMessageSentTo: destination,
                                         with: ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress),
                                         to: source, using: keySet)
                    break
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
                        networkManager.reply(toMessageSentTo: destination,
                                             with: ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress),
                                             to: source, using: keySet)
                        break
                    }
                }
                save()
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelSubscriptionStatus(confirmAdding: group!, to: model),
                                     to: source, using: keySet)
            } else {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelSubscriptionStatus(responseTo: request, with: .invalidModel),
                                     to: source, using: keySet)
            }
            
        case let request as ConfigModelSubscriptionDelete:
            if let element = localNode.element(withAddress: destination),
               let model = element.model(withModelId: request.modelId) {
                guard request.address.isGroup && request.address != Address.allNodes else {
                    networkManager.reply(toMessageSentTo: destination,
                                         with: ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress),
                                         to: source, using: keySet)
                    break
                }
                model.unsubscribe(from: request.address)
                save()
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelSubscriptionStatus(confirmDeleting: request.address, from: model),
                                     to: source, using: keySet)
            } else {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelSubscriptionStatus(responseTo: request, with: .invalidModel),
                                     to: source, using: keySet)
            }
            
        case let request as ConfigModelSubscriptionVirtualAddressAdd:
            if let element = localNode.element(withAddress: destination),
               let model = element.model(withModelId: request.modelId) {
                var group = meshNetwork.group(withAddress: MeshAddress(request.virtualLabel))
                if group != nil {
                    model.subscribe(to: group!)
                } else {
                    do {
                        group = try Group(name: "New Group", address: MeshAddress(request.virtualLabel))
                        try meshNetwork.add(group: group!)
                        model.subscribe(to: group!)
                    } catch {
                        networkManager.reply(toMessageSentTo: destination,
                                             with: ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress),
                                             to: source, using: keySet)
                        break
                    }
                }
                save()
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelSubscriptionStatus(confirmAdding: group!, to: model),
                                     to: source, using: keySet)
            } else {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelSubscriptionStatus(responseTo: request, with: .invalidModel),
                                     to: source, using: keySet)
            }
            
        case let request as ConfigModelSubscriptionVirtualAddressOverwrite:
            if let element = localNode.element(withAddress: destination),
               let model = element.model(withModelId: request.modelId) {
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
                        networkManager.reply(toMessageSentTo: destination,
                                             with: ConfigModelSubscriptionStatus(responseTo: request, with: .invalidAddress),
                                             to: source, using: keySet)
                        break
                    }
                }
                save()
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelSubscriptionStatus(confirmAdding: group!, to: model),
                                     to: source, using: keySet)
            } else {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelSubscriptionStatus(responseTo: request, with: .invalidModel),
                                     to: source, using: keySet)
            }
            
        case let request as ConfigModelSubscriptionVirtualAddressDelete:
            if let element = localNode.element(withAddress: destination),
               let model = element.model(withModelId: request.modelId) {
                let address = MeshAddress(request.virtualLabel)
                if let group = meshNetwork.group(withAddress: address) {
                    model.unsubscribe(from: group)
                    save()
                }
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelSubscriptionStatus(confirmDeleting: address.address, from: model),
                                     to: source, using: keySet)
            } else {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelSubscriptionStatus(responseTo: request, with: .invalidModel),
                                     to: source, using: keySet)
            }
            
        case let request as ConfigModelSubscriptionDeleteAll:
            if let element = localNode.element(withAddress: destination),
               let model = element.model(withModelId: request.modelId) {
                model.unsubscribeFromAll()
                save()
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelSubscriptionStatus(confirmDeletingAllFrom: model),
                                     to: source, using: keySet)
            } else {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigModelSubscriptionStatus(responseTo: request, with: .invalidModel),
                                     to: source, using: keySet)
            }
            
        case let status as ConfigModelSubscriptionStatus:
            if status.isSuccess,
                let node = meshNetwork.node(withAddress: source),
                let element = node.element(withAddress: status.elementAddress),
                let model = element.model(withModelId: status.modelId) {
                let address = MeshAddress(status.address)
                
                // The status for Delete All request has an invalid address.
                // Handle it differently here.
                if let _ = requests[source] as? ConfigModelSubscriptionDeleteAll {
                    model.subscribe.removeAll()
                    save()
                    requests.removeValue(forKey: source)
                }
                // Here it should be safe to search for the group.
                guard let group = meshNetwork.group(withAddress: address) else {
                    requests.removeValue(forKey: source)
                    return
                }
                switch requests[source] {
                case is ConfigModelSubscriptionOverwrite, is ConfigModelSubscriptionVirtualAddressOverwrite:
                    model.subscribe.removeAll()
                    fallthrough
                case is ConfigModelSubscriptionAdd, is ConfigModelSubscriptionVirtualAddressAdd:
                    model.subscribe(to: group)
                    save()
                    requests.removeValue(forKey: source)
                case is ConfigModelSubscriptionDelete, is ConfigModelSubscriptionVirtualAddressDelete:
                    model.unsubscribe(from: group)
                    save()
                    requests.removeValue(forKey: source)
                default:
                    break
                }
            }
            
        case let request as ConfigSIGModelSubscriptionGet:
            if let element = localNode.element(withAddress: destination),
                let model = element.model(withModelId: request.modelId) {
                let addresses = model.subscriptions.map { $0.address.address }
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigSIGModelSubscriptionList(responseTo: request, with: addresses),
                                     to: source, using: keySet)
            } else {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigSIGModelSubscriptionList(responseTo: request, with: .invalidModel),
                                     to: source, using: keySet)
            }
            
        case let request as ConfigVendorModelSubscriptionGet:
            if let element = localNode.element(withAddress: destination),
                let model = element.model(withModelId: request.modelId) {
                let addresses = model.subscriptions.map { $0.address.address }
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigVendorModelSubscriptionList(responseTo: request, with: addresses),
                                     to: source, using: keySet)
            } else {
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigVendorModelSubscriptionList(responseTo: request, with: .invalidModel),
                                     to: source, using: keySet)
            }
            
        case let list as ConfigModelSubscriptionList:
            if list.isSuccess,
                let node = meshNetwork.node(withAddress: source),
                let element = node.element(withAddress: list.elementAddress),
                let model = element.model(withModelId: list.modelId) {
                model.subscribe.removeAll()
                for address in list.addresses {
                    if let group = meshNetwork.groups.first(where: { $0.address.address == address }) {
                        model.subscribe.append(group.address.hex)
                    } else {
                        model.subscribe.append(address.hex)
                    }
                }
                save()
            }
            
        // Default TTL
        case let request as ConfigDefaultTtlSet:
            localNode.defaultTTL = request.ttl
            save()
            networkManager.reply(toMessageSentTo: destination,
                                 with: ConfigDefaultTtlStatus(ttl: localNode.defaultTTL ?? networkManager.defaultTtl),
                                 to: source, using: keySet)
            
        case is ConfigDefaultTtlGet:
            networkManager.reply(toMessageSentTo: destination,
                                 with: ConfigDefaultTtlStatus(ttl: localNode.defaultTTL ?? networkManager.defaultTtl),
                                 to: source, using: keySet)
            
        case let defaultTtl as ConfigDefaultTtlStatus:
            if let node = meshNetwork.node(withAddress: source) {
                node.ttl = defaultTtl.ttl
                save()
            }
            
        // Relay settings
        case is ConfigRelayGet, is ConfigRelaySet:
            // Relay feature is not supported.
            networkManager.reply(toMessageSentTo: destination,
                                 with: ConfigRelayStatus(.notSupported, count: 0, steps: 0),
                                 to: source, using: keySet)
            
        case let status as ConfigRelayStatus:
            if let node = meshNetwork.node(withAddress: source) {
                node.ensureFeatures.relay = status.state
                if case .notSupported = status.state {
                    node.relayRetransmit = nil
                } else {
                    node.relayRetransmit = Node.RelayRetransmit(status)
                }
                save()
            }
            
        // GATT Proxy settings
        case is ConfigGATTProxyGet, is ConfigGATTProxySet:
            // Relay feature is not supported.
            networkManager.reply(toMessageSentTo: destination,
                                 with: ConfigGATTProxyStatus(.notSupported),
                                 to: source, using: keySet)
            
        case let status as ConfigGATTProxyStatus:
            if let node = meshNetwork.node(withAddress: source) {
                node.ensureFeatures.proxy = status.state
                save()
            }
            
        // Friend settings
        case is ConfigFriendGet, is ConfigFriendSet:
            // Friend feature is not supported.
            networkManager.reply(toMessageSentTo: destination,
                                 with: ConfigFriendStatus(.notSupported),
                                 to: source, using: keySet)
            
        case let status as ConfigFriendStatus:
            if let node = meshNetwork.node(withAddress: source) {
                node.ensureFeatures.friend = status.state
                save()
            }
            
        // Secure Network Beacon configuration
        case is ConfigBeaconGet, is ConfigBeaconSet:
            // Secure Network Beacon feature is not supported.
            networkManager.reply(toMessageSentTo: destination,
                                 with: ConfigBeaconStatus(enabled: false),
                                 to: source, using: keySet)
            
        case let status as ConfigBeaconStatus:
            if let node = meshNetwork.node(withAddress: source) {
                node.secureNetworkBeacon = status.isEnabled
                save()
            }
            
        // Network Transmit settings
        case let request as ConfigNetworkTransmitSet:
            localNode.networkTransmit = Node.NetworkTransmit(request)
            save()
            fallthrough
            
        case is ConfigNetworkTransmitGet:
            networkManager.reply(toMessageSentTo: destination,
                                 with: ConfigNetworkTransmitStatus(for: localNode),
                                 to: source, using: keySet)
            
        case let status as ConfigNetworkTransmitStatus:
            if let node = meshNetwork.node(withAddress: source) {
                node.networkTransmit = Node.NetworkTransmit(status)
                save()
            }
            
        // Resetting Node
        case is ConfigNodeReset:
            // Reset the network. Keep the same Provisioner and network settings.
            if let provisioner = meshNetwork.localProvisioner {
                // Replying with ConfigNodeResetStatus() may fail, as the network is
                // being reset and forgotten in a second.
                networkManager.reply(toMessageSentTo: destination,
                                     with: ConfigNodeResetStatus(),
                                     to: source, using: keySet)
                
                let localElements = meshNetwork.localElements
                provisioner.meshNetwork = nil
                let manager = networkManager.manager
                    .createNewMeshNetwork(withName: meshNetwork.meshName, by: provisioner)
                manager.localElements = localElements
                save()
            }
            
        case is ConfigNodeResetStatus:
            if let node = meshNetwork.node(withAddress: source) {
                meshNetwork.remove(node: node)
                save()
            }
            
        default:
            break
        }
    }
    
    /// This method handles the Mesh Message that is about to being sent,
    /// depending on its type.
    ///
    /// - parameter configMessage: The Mesh Message to be sent.
    /// - parameter destination:   The Unicast Address of the target Node.
    /// - returns: `True`, if the message can be send, otherwise `false`.
    func handle(configMessage: ConfigMessage, to destination: Address) -> Bool {
        switch configMessage {
            
        // Those messages are ACK on the Foundation Layer with Config...Status.
        // The action taken upon receiving the status depends on the request.
        case is ConfigNetKeyAdd, is ConfigNetKeyDelete, is ConfigNetKeyUpdate:
            requests[destination] = configMessage
                
        case is ConfigAppKeyAdd, is ConfigAppKeyDelete, is ConfigAppKeyUpdate:
            requests[destination] = configMessage
            
        case is ConfigModelAppBind, is ConfigModelAppUnbind:
            requests[destination] = configMessage
            
        case is ConfigModelPublicationSet, is ConfigModelPublicationVirtualAddressSet, is ConfigModelPublicationGet:
            requests[destination] = configMessage
            
        case is ConfigModelSubscriptionAdd, is ConfigModelSubscriptionDelete, is ConfigModelSubscriptionDeleteAll,
             is ConfigModelSubscriptionOverwrite, is ConfigModelSubscriptionVirtualAddressAdd,
             is ConfigModelSubscriptionVirtualAddressDelete, is ConfigModelSubscriptionVirtualAddressOverwrite:
            requests[destination] = configMessage
            
        default:
            break
        }
        return true
    }
}

private extension FoundationLayer {
    
    /// Save the state of the mesh network to the storage associated with
    /// the manager. This method ignores the result of saving.
    private func save() {
        _ = networkManager.manager.save()
    }
    
}
