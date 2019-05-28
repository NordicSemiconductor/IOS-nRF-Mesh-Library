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
    
    // MARK: - Computed properties
    
    var delegate: MeshNetworkDelegate? {
        return meshNetworkManager.delegate
    }
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
        
    }
    
    /// This method handles the received PDU of given type.
    ///
    /// - parameter pdu:  The data received.
    /// - parameter type: The PDU type.
    func handleIncomingPdu(_ pdu: Data, ofType type: PduType) {
        networkLayer.handleIncomingPdu(pdu, ofType: type)
    }
    
    /// Encrypts the message with given destination address and,
    /// if required, performs segmentation. For each created segment
    /// the transmitter's `send(:ofType)` will be called.
    /// The transmitter should send the message over Bluetooth Mesh
    /// using any bearer.
    ///
    /// This method does not return PDUs to be sent. Instead, for each
    /// segment it calls a callback which should send it over the air.
    /// This is in order to support retransmittion in case a packet was
    /// lost and needs to be sent again after block acknowlegment was
    /// received.
    ///
    /// - parameter message:     The message to be sent.
    /// - parameter destination: The destination address.
    func sendMeshMessage(_ message: MeshMessage, to destination: MeshAddress) {
        // TODO
    }
}
