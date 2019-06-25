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
    /// - parameter message: The Mesh Message to send.
    /// - parameter destination: The destination Address. This must be a Unicast Address.
    func send(_ message: ConfigMessage, to destination: Address) {
        networkManager.upperTransportLayer.send(message, to: destination)
    }
    
}

private extension AccessLayer {
    
    func handle(accessPdu: AccessPdu) {
        var message: MeshMessage?
        
        switch accessPdu.opCode {
            
        // Composition Data
        case ConfigCompositionDataGet.opCode:
            message = ConfigCompositionDataGet(parameters: accessPdu.parameters)
            
        case ConfigCompositionDataStatus.opCode:
            message = ConfigCompositionDataStatus(parameters: accessPdu.parameters)
            
        // App Keys Management
        case ConfigAppKeyAdd.opCode:
            message = ConfigAppKeyAdd(parameters: accessPdu.parameters)
            
        case ConfigAppKeyUpdate.opCode:
            message = ConfigAppKeyUpdate(parameters: accessPdu.parameters)
            
        case ConfigAppKeyStatus.opCode:
            message = ConfigAppKeyStatus(parameters: accessPdu.parameters)
            
        // Resetting Node
        case ConfigNodeReset.opCode:
            message = ConfigNodeReset(parameters: accessPdu.parameters)
            
        case ConfigNodeResetStatus.opCode:
            message = ConfigNodeResetStatus(parameters: accessPdu.parameters)
            
        // Default TTL
        case ConfigDefaultTtlGet.opCode:
            message = ConfigDefaultTtlGet(parameters: accessPdu.parameters)
        
        case ConfigDefaultTtlSet.opCode:
            message = ConfigDefaultTtlSet(parameters: accessPdu.parameters)
            
        case ConfigDefaultTtlStatus.opCode:
            message = ConfigDefaultTtlStatus(parameters: accessPdu.parameters)
            
            
        default:
            message = nil
        }
        
        if let message = message {
            networkManager.notifyAbout(message, from: accessPdu.source)
        }
    }
    
}
