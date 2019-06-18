//
//  NetworkManager.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 28/05/2019.
//

import Foundation

internal class NetworkManager {
    let meshNetworkManager: MeshNetworkManager
    
    // MARK: - Layers
    
    var networkLayer: NetworkLayer!
    var lowerTransportLayer: LowerTransportLayer!
    var upperTransportLayer: UpperTransportLayer!
    var accessLayer: AccessLayer!
    
    // MARK: - Computed properties
    
    var transmitter: Transmitter? {
        return meshNetworkManager.transmitter
    }
    var meshNetwork: MeshNetwork? {
        return meshNetworkManager.meshNetwork
    }
    
    // MARK: - Implementation
    
    init(_ meshNetworkManager: MeshNetworkManager) {
        self.meshNetworkManager = meshNetworkManager
        
        networkLayer = NetworkLayer(self)
        lowerTransportLayer = LowerTransportLayer(self)
        upperTransportLayer = UpperTransportLayer(self)
        accessLayer = AccessLayer(self)
    }
    
    /// This method handles the received PDU of given type.
    ///
    /// - parameter pdu:  The data received.
    /// - parameter type: The PDU type.
    func handle(incomingPdu pdu: Data, ofType type: PduType) {
        networkLayer.handle(incomingPdu: pdu, ofType: type)
    }
    
    /// Encrypts the message with the Application Key and a Network Key
    /// bound to it, and sends to the given destination address.
    ///
    /// This method does not send nor return PDUs to be sent. Instead,
    /// for each created segment it calls transmitter's `send(:ofType)`,
    /// which should send the PDU over the air. This is in order to support
    /// retransmittion in case a packet was lost and needs to be sent again
    /// after block acknowlegment was received.
    ///
    /// - parameter message:        The message to be sent.
    /// - parameter destination:    The destination address.
    /// - parameter applicationKey: The Application Key to sign the message.
    func send(_ message: MeshMessage, to destination: Address, using applicationKey: ApplicationKey) {
        accessLayer.send(message, to: destination, using: applicationKey)
    }
    
    /// Encrypts the message with the Device Key and the first Network Key
    /// known to the target device, and sends to the given destination address.
    ///
    /// This method does not send nor return PDUs to be sent. Instead,
    /// for each created segment it calls transmitter's `send(:ofType)`,
    /// which should send the PDU over the air. This is in order to support
    /// retransmittion in case a packet was lost and needs to be sent again
    /// after block acknowlegment was received.
    ///
    /// - parameter message:        The message to be sent.
    /// - parameter destination:    The destination address.
    func send(_ configMessage: ConfigMessage, to destination: Address) {
        guard destination.isUnicast else {
            return
        }
        accessLayer.send(configMessage, to: destination)
    }
    
    func notifyAbout(_ message: MeshMessage, from source: Address) {
        meshNetworkManager.delegate?.meshNetwork(meshNetwork!, didDeliverMessage: message, from: source)
    }
}
