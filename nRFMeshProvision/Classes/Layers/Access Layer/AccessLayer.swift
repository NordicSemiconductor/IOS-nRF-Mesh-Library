//
//  AccessLayer.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 29/05/2019.
//

import Foundation

internal class AccessLayer {
    let networkManager: NetworkManager
    
    init(_ networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    /// This method handles the Upper Transport PDU and reads the Opcode.
    /// If the Opcode is supported, a message object is created and sent
    /// to the delegate. Otherwise, a generic MeshMessage object is created
    /// for the app to handle.
    ///
    /// - parameter upperTransportPdu: The decoded Upper Transport PDU.
    func handle(upperTransportPdu: UpperTransportPdu) {
        guard let accessPdu = AccessPdu(fromUpperTransportPdu: upperTransportPdu) else {
            return
        }
        handle(accessPdu: accessPdu)
    }
    
    /// Sends the MeshMessage to the destination. The message is encrypted
    /// using given Application Key and a Network Key bound to it.
    ///
    /// - parameter message: The Mesh Message to send.
    /// - parameter destination: The destination Address. This can be any
    ///                          valid mesh Address.
    /// - parameter applicationKey: The Application Key to sign the message with.
    func send(_ message: MeshMessage, to destination: Address, using applicationKey: ApplicationKey) {
        networkManager.upperTransportLayer.send(message, to: destination, using: applicationKey)
    }
    
    /// Sends the ConfigMessage to the destination. The message is encrypted
    /// using the Device Key which belongs to the target Node, and first
    /// Network Key known to this Node.
    ///
    /// - parameter message: The Mesh Config Message to send.
    /// - parameter destination: The destination Address. This must be a Unicast Address.
    func send(_ message: ConfigMessage, to destination: Address) {
        guard destination.isUnicast else {
            print("Error: Address: 0x\(destination.hex) is not a Unicast Address")
            return
        }
        handle(configMessage: message, to: destination)
        networkManager.upperTransportLayer.send(message, to: destination)
    }
    
}

private extension AccessLayer {
    
    /// This method converts the received Access PDU to a Mesh Message and
    /// sends to `handle(meshMessage:from)` if message was successfully created.
    ///
    /// - parameter accessPdu: The Access PDU received.
    func handle(accessPdu: AccessPdu) {
        var MessageType: MeshMessage.Type?
        
        switch accessPdu.opCode {
            
        // Composition Data
        case ConfigCompositionDataGet.opCode:
            MessageType = ConfigCompositionDataGet.self
            
        case ConfigCompositionDataStatus.opCode:
            MessageType = ConfigCompositionDataStatus.self
            
        // Net Keys Management
        case ConfigNetKeyAdd.opCode:
            MessageType = ConfigNetKeyAdd.self
            
        case ConfigNetKeyDelete.opCode:
            MessageType = ConfigNetKeyDelete.self
            
        case ConfigNetKeyUpdate.opCode:
            MessageType = ConfigNetKeyUpdate.self
            
        case ConfigNetKeyStatus.opCode:
            MessageType = ConfigNetKeyStatus.self
            
        case ConfigNetKeyGet.opCode:
            MessageType = ConfigNetKeyGet.self
            
        case ConfigNetKeyList.opCode:
            MessageType = ConfigNetKeyList.self
            
        // App Keys Management
        case ConfigAppKeyAdd.opCode:
            MessageType = ConfigAppKeyAdd.self
            
        case ConfigAppKeyDelete.opCode:
            MessageType = ConfigAppKeyDelete.self
            
        case ConfigAppKeyUpdate.opCode:
            MessageType = ConfigAppKeyUpdate.self
            
        case ConfigAppKeyStatus.opCode:
            MessageType = ConfigAppKeyStatus.self
            
        case ConfigAppKeyGet.opCode:
            MessageType = ConfigAppKeyGet.self
            
        case ConfigAppKeyList.opCode:
            MessageType = ConfigAppKeyList.self
            
        // Resetting Node
        case ConfigNodeReset.opCode:
            MessageType = ConfigNodeReset.self
            
        case ConfigNodeResetStatus.opCode:
            MessageType = ConfigNodeResetStatus.self
            
        // Default TTL
        case ConfigDefaultTtlGet.opCode:
            MessageType = ConfigDefaultTtlGet.self
        
        case ConfigDefaultTtlSet.opCode:
            MessageType = ConfigDefaultTtlSet.self
            
        case ConfigDefaultTtlStatus.opCode:
            MessageType = ConfigDefaultTtlStatus.self
            
        default:
            MessageType = nil
        }
        
        if let MessageType = MessageType,
           let message = MessageType.init(parameters: accessPdu.parameters) {
            if let configMessage = message as? ConfigMessage {
                handle(configMessage: configMessage, from: accessPdu.source)
            }
            networkManager.notifyAbout(message, from: accessPdu.source)
        }
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
