//
//  UpperTransportLayer.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 28/05/2019.
//

import Foundation

internal class UpperTransportLayer {
    let networkManager: NetworkManager
    let meshNetwork: MeshNetwork
    let defaults: UserDefaults
    
    init(_ networkManager: NetworkManager) {
        self.networkManager = networkManager
        self.meshNetwork = networkManager.meshNetwork!
        self.defaults = UserDefaults(suiteName: meshNetwork.uuid.uuidString)!
    }
    
    /// Handles received Lower Transport PDU.
    /// Depending on the PDU type, the message will be either propagated to
    /// Access Layer, or handled internally.
    ///
    /// - parameter lowetTransportPdu: The Lower Trasport PDU received.
    func handle(lowerTransportPdu: LowerTransportPdu) {
        switch lowerTransportPdu.type {
        case .accessMessage:
            let accessMessage = lowerTransportPdu as! AccessMessage
            if let (upperTransportPdu, keySet) = UpperTransportPdu.decode(accessMessage, for: meshNetwork) {
                networkManager.accessLayer.handle(upperTransportPdu: upperTransportPdu, sentWith: keySet)
            }
        case .controlMessage:
            let controlMessage = lowerTransportPdu as! ControlMessage
            switch controlMessage.opCode {
            case 0x0A:
                if let heartbeat = HearbeatMessage(fromControlMessage: controlMessage) {
                    handle(hearbeat: heartbeat)
                }
            default:
                // Other Control Messages are not supported.
                break
            }
        }
    }
    
    /// Handles the Mesh Message and sends it down to Lower Transport Layer.
    ///
    /// - parameter message: The message to be sent.
    /// - parameter localElement: The local Element which address will be used as source.
    /// - parameter destination: The destination address.
    /// - parameter keySet: The set of keys to encrypt the message with.
    func send(_ message: MeshMessage,
              from localElement: Element, to destination: MeshAddress,
              using keySet: KeySet) {
        // Get the current sequence number for local Provisioner's source address.
        let sequence = UInt32(defaults.integer(forKey: "S\(localElement.unicastAddress.hex)"))
        
        let pdu = UpperTransportPdu(fromMeshMessage: message,
                                    sentFrom: localElement, to: destination,
                                    usingKeySet: keySet, sequence: sequence)
        
        let isSegmented = pdu.transportPdu.count > 15 || message.isSegmented
        let networkKey = keySet.networkKey
        networkManager.lowerTransportLayer.send(upperTransportPdu: pdu,
                                                asSegmentedMessage: isSegmented,
                                                usingNetworkKey: networkKey)
    }
    
}

private extension UpperTransportLayer {
    
    func handle(hearbeat: HearbeatMessage) {
        // TODO: Implement handling Heartbeat messages
    }
    
}
