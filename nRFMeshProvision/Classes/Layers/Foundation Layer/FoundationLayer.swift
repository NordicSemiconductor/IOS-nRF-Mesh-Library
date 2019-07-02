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
                case is ConfigNetKeyUpdate:
                    guard let netKey = node.netKeys[netKeyStatus.networkKeyIndex] else {
                        break
                    }
                    netKey.updated = true
                    save()
                case is ConfigNetKeyDelete:
                    node.remove(networkKeyIndex: netKeyStatus.networkKeyIndex)
                    save()
                default:
                    break
                }
            }
            requests.removeValue(forKey: source)
            
        case let appKeyStatus as ConfigAppKeyStatus:
            if appKeyStatus.isSuccess, let node = meshNetwork.node(withAddress: source) {
                switch requests[source] {
                case is ConfigAppKeyAdd:
                    guard node.appKeys[appKeyStatus.applicationKeyIndex] == nil else {
                        break
                    }
                    node.appKeys.append(Node.NodeKey(index: appKeyStatus.applicationKeyIndex, updated: false))
                    save()
                case is ConfigAppKeyUpdate:
                    guard let appKey = node.appKeys[appKeyStatus.applicationKeyIndex] else {
                        break
                    }
                    appKey.updated = true
                    save()
                case is ConfigAppKeyDelete:
                    node.remove(applicationKeyIndex: appKeyStatus.applicationKeyIndex)
                    save()
                default:
                    break
                }
            }
            requests.removeValue(forKey: source)
            
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
            
        // Those messages are ACK on the Foundation Layer with Config...KeyStatus.
        // The action taken upon receiving the status depends on the request.
        // Here we also have to ensure that no two requests are sent to the same
        // destination address before a status is received.
        case is ConfigNetKeyAdd, is ConfigNetKeyDelete, is ConfigNetKeyUpdate,
             is ConfigAppKeyAdd, is ConfigAppKeyDelete, is ConfigAppKeyUpdate:
            guard requests[destination] == nil else {
                return false
            }
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
