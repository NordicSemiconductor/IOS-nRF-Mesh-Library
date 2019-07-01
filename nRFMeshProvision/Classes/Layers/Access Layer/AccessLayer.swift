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
        networkManager.foundationLayer.handle(configMessage: message, to: destination)
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
                networkManager.foundationLayer.handle(configMessage: configMessage, from: accessPdu.source)
            }
            networkManager.notifyAbout(message, from: accessPdu.source)
        }
    }
    
}
