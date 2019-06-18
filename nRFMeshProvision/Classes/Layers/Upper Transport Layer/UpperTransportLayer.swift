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
            if let upperTransportPdu = UpperTransportPdu.decode(accessMessage, for: meshNetwork) {
                networkManager.accessLayer.handle(upperTransportPdu: upperTransportPdu)
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
    /// - parameter destination: The destination address. This can be any type of
    ///                          valid address.
    /// - parameter applicationKey: The Application Key to sign the message with.
    func send(_ message: MeshMessage, to destination: Address, using applicationKey: ApplicationKey) {
        guard destination.isValidAddress else {
            return
        }
        guard let source = meshNetwork.localProvisioner?.unicastAddress else {
            return
        }
        
        // Get the current sequence number for local Provisioner's source address.
        let sequence = UInt32(defaults.integer(forKey: source.hex))
        let networkKey = applicationKey.boundNetworkKey
        let ivIndex = networkKey.ivIndex
        
        let pdu = UpperTransportPdu(fromMeshMessage: message,
                                    sentFrom: source, to: destination,
                                    usingApplicationKey: applicationKey, sequence: sequence, andIvIndex: ivIndex)
        let isSegmented = pdu.transportPdu.count > 15 || message.isSegmented
        networkManager.lowerTransportLayer.send(upperTransportPdu: pdu, asSegmentedMessage: isSegmented,
                                                usingNetworkKey: networkKey)
    }
    
    /// Handles the Config Message and sends it down to Lower Transport Layer.
    ///
    /// - parameter message: The message to be sent.
    /// - parameter destination: The destination address. This must be a Unicast Address.
    func send(_ message: ConfigMessage, to destination: Address) {
        guard destination.isUnicast else {
            return
        }
        guard let source = meshNetwork.localProvisioner?.unicastAddress else {
            return
        }
        guard let node = meshNetwork.node(withAddress: destination),
            let networkKey = node.networkKeys.first else {
            return
        }
        
        // Get the current sequence number for local Provisioner's source address.
        let sequence = UInt32(defaults.integer(forKey: source.hex))
        let ivIndex = networkKey.ivIndex
        
        let pdu = UpperTransportPdu(fromConfigMessage: message,
                                    sentFrom: source, to: destination,
                                    usingDeviceKey: node.deviceKey, sequence: sequence, andIvIndex: ivIndex)
        let isSegmented = pdu.transportPdu.count > 15 || message.isSegmented
        networkManager.lowerTransportLayer.send(upperTransportPdu: pdu, asSegmentedMessage: isSegmented,
                                                usingNetworkKey: networkKey)
    }
    
}

private extension UpperTransportLayer {
    
    func handle(hearbeat: HearbeatMessage) {
        // TODO: Implement handling Heartbeat messages
    }
    
}
