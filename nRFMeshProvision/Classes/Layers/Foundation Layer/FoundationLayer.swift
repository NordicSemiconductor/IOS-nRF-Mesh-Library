//
//  FoundationLayer.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 01/07/2019.
//

import Foundation

internal class FoundationLayer {
    let networkManager: NetworkManager
    
    init(_ networkManager: NetworkManager) {
        self.networkManager = networkManager
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
            if netKeyStatus.status == .success,
                let node = meshNetwork.node(withAddress: source) {
                // Did the Node already know this Key Index? If yes, an Update must
                // have been sent.
                if let netKey = node.netKeys[netKeyStatus.networkKeyIndex] {
                    // Note: This may actually be wrong: When ConfigNetKeyAdd was sent twice to
                    //       the same Node with the same Key Index, this will assume the second
                    //       message to be ConfigNetKeyUpdate.
                    netKey.updated = true
                } else {
                    node.netKeys.append(Node.NodeKey(index: netKeyStatus.networkKeyIndex, updated: false))
                }
                save()
            }
            
        case let appKeyStatus as ConfigAppKeyStatus:
            if appKeyStatus.status == .success,
                let node = meshNetwork.node(withAddress: source) {
                // Did the Node already know this Key Index? If yes, an Update must
                // have been sent.
                if let appKey = node.appKeys[appKeyStatus.applicationKeyIndex] {
                    // Note: This may actually be wrong: When ConfigAppKeyAdd was sent twice to
                    //       the same Node with the same Key Index, this will assume the second
                    //       message to be ConfigAppKeyUpdate.
                    appKey.updated = true
                } else {
                    node.appKeys.append(Node.NodeKey(index: appKeyStatus.applicationKeyIndex, updated: false))
                }
                save()
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
    func handle(configMessage: ConfigMessage, to destination: Address) {
        switch configMessage {
            
        default:
            break
        }
    }
    
    /// Save the state of the mesh network to the storage associated with
    /// the manager. This method ignores the result of saving.
    func save() {
        _ = networkManager.meshNetworkManager.save()
    }
}
