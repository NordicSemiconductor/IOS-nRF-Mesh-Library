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
    func handle(configMessage: ConfigMessage, from source: Address) {
        guard let meshNetwork = networkManager.meshNetwork else {
            return
        }
        
        switch configMessage {
            
        case let compositionData as ConfigCompositionDataStatus:
            if let node = meshNetwork.node(withAddress: source) {
                node.apply(compositionData: compositionData)
                save()
            }
            
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
                    node.remove(networkKeyIndex: netKeyStatus.networkKeyIndex)
                    // When a Network Key was deleted, all Application Keys bound to it were
                    // removed as well.
                    // First, go through all removed Application Keys and unbind them from all
                    // Models, then remove publications that were using them.
                    node.applicationKeys.filter({ $0.boundNetworkKeyIndex == netKeyStatus.networkKeyIndex}).forEach { key in
                        // If the removed Application Key was used in any of Node's Models,
                        // clear all the usages of it.
                        node.elements.flatMap({ $0.models }).forEach { model in
                            // Remove the Key Index from bound keys.
                            model.bind = model.bind.filter { $0 != key.index }
                            // Clear publication if it was set to use the removed Application Key.
                            if let publish = model.publish, publish.index == key.index {
                                model.publish = nil
                            }
                        }
                    }
                    // At last, remove all indexes of keys bound to the deleted Network Key.
                    node.appKeys = node.appKeys.filter { $0.index != netKeyStatus.networkKeyIndex }
                    save()
                    requests.removeValue(forKey: source)
                default:
                    break
                }
            }
            
        case let list as ConfigNetKeyList:
            if let node = meshNetwork.node(withAddress: source) {
                node.netKeys.removeAll()
                node.netKeys.append(contentsOf: list.networkKeyIndexs.map({ Node.NodeKey(index: $0, updated: false) }))
                node.netKeys.sort()
                save()
            }
            
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
                    node.remove(applicationKeyIndex: appKeyStatus.applicationKeyIndex)
                    // If the removed Application Key was used in any of Node's Models,
                    // clear all the usages of it.
                    node.elements.flatMap({ $0.models }).forEach { model in
                        // Remove the Key Index from bound keys.
                        model.bind = model.bind.filter { $0 != appKeyStatus.applicationKeyIndex }
                        // Clear publication if it was set to use the removed Application Key.
                        if let publish = model.publish, publish.index == appKeyStatus.applicationKeyIndex {
                            model.publish = nil
                        }
                    }
                    save()
                    requests.removeValue(forKey: source)
                default:
                    break
                }
            }
            
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
            
        case let status as ConfigModelAppStatus:
            if status.isSuccess,
                let node = meshNetwork.node(withAddress: source),
                let element = node.element(withAddress: status.elementAddress),
                let model = element.model(withModelId: status.modelId) {
                switch requests[source] {
                case is ConfigModelAppBind:
                    guard !model.bind.contains(status.applicationKeyIndex) else {
                        break
                    }
                    model.bind.append(status.applicationKeyIndex)
                    model.bind.sort()
                    save()
                    requests.removeValue(forKey: source)
                case is ConfigModelAppUnbind:
                    guard let index = model.bind.firstIndex(of: status.applicationKeyIndex) else {
                        break
                    }
                    model.bind.remove(at: index)
                    // If this Application Key was used for publication, the publication has been cancelled.
                    if let publish = model.publish, publish.index == status.applicationKeyIndex {
                        model.publish = nil
                    }
                    save()
                    requests.removeValue(forKey: source)
                default:
                    break
                }
            }
            
        case let status as ConfigModelPublicationStatus:
            if status.isSuccess,
                let node = meshNetwork.node(withAddress: source),
                let element = node.element(withAddress: status.elementAddress),
                let model = element.model(withModelId: status.modelId) {
                switch requests[source] {
                case is ConfigModelPublicationSet:
                    if !status.publish.publicationAddress.address.isUnassigned {
                        model.publish = status.publish
                    } else {
                        // An unassigned Address is sent to remove the publication.
                        model.publish = nil
                    }
                    save()
                case let request as ConfigModelPublicationVirtualAddressSet:
                    // Note: The Publish from the request has the Virtual Label set,
                    //       while the status has only the 16-bit Virtual Address.
                    // Note: We assume here, that the response is identical to the
                    //       request, with an exception of the Virtual Label.
                    model.publish = request.publish
                    save()
                case is ConfigModelPublicationGet:
                    // TODO: The Virtual Label must be obtained from somewhere,
                    //       as the status has only the 16-bit Virtual Address.
                    model.publish = status.publish
                    save()
                default:
                    break
                }
            }
            
        case let defaultTtl as ConfigDefaultTtlStatus:
            if let node = meshNetwork.node(withAddress: source) {
                node.apply(defaultTtl: defaultTtl)
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
        _ = networkManager.meshNetworkManager.save()
    }
    
}
