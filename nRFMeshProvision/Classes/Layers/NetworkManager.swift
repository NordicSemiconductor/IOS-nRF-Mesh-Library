//
//  NetworkManager.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 28/05/2019.
//

import Foundation

internal class NetworkManager {
    let manager: MeshNetworkManager
    
    // MARK: - Layers
    
    var networkLayer        : NetworkLayer!
    var lowerTransportLayer : LowerTransportLayer!
    var upperTransportLayer : UpperTransportLayer!
    var accessLayer         : AccessLayer!
    var foundationLayer     : FoundationLayer!
    
    // MARK: - Computed properties
    
    var transmitter: Transmitter? {
        return manager.transmitter
    }
    var meshNetwork: MeshNetwork? {
        return manager.meshNetwork
    }
    var defaultTtl: UInt8 {
        return max(min(manager.defaultTtl, 127), 2)
    }
    var incompleteMessageTimeout: TimeInterval {
        return max(manager.incompleteMessageTimeout, 10.0)
    }
    func acknowledgmentTimerInterval(_ ttl: UInt8) -> TimeInterval {
        return max(manager.acknowledgmentTimerInterval, 0.150) + Double(ttl) * 0.050
    }
    func transmissionTimerInteral(_ ttl: UInt8) -> TimeInterval {
        return max(manager.transmissionTimerInteral, 0.200) + Double(ttl) * 0.050
    }
    var retransmissionLimit: Int {
        return max(manager.retransmissionLimit, 2)
    }
    
    // MARK: - Implementation
    
    init(_ meshNetworkManager: MeshNetworkManager) {
        manager = meshNetworkManager
        
        networkLayer = NetworkLayer(self)
        lowerTransportLayer = LowerTransportLayer(self)
        upperTransportLayer = UpperTransportLayer(self)
        accessLayer = AccessLayer(self)
        foundationLayer = FoundationLayer(self)
    }
    
    // MARK: - Receiving messages
    
    /// This method handles the received PDU of given type.
    ///
    /// - parameter pdu:  The data received.
    /// - parameter type: The PDU type.
    func handle(incomingPdu pdu: Data, ofType type: PduType) {
        networkLayer.handle(incomingPdu: pdu, ofType: type)
    }
    
    // MARK: - Sending messages
    
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
    /// - parameter element:        The source Element.
    /// - parameter destination:    The destination address.
    /// - parameter applicationKey: The Application Key to sign the message.
    func send(_ message: MeshMessage,
              from element: Element, to destination: MeshAddress,
              using applicationKey: ApplicationKey) {
        accessLayer.send(message, from: element, to: destination, using: applicationKey)
    }
    
    /// Encrypts the message with the Device Key and the first Network Key
    /// known to the target device, and sends to the given destination address.
    ///
    /// The `ConfigNetKeyDelete` will be signed with a different Network Key
    /// that is being removed.
    ///
    /// This method does not send nor return PDUs to be sent. Instead,
    /// for each created segment it calls transmitter's `send(:ofType)`,
    /// which should send the PDU over the air. This is in order to support
    /// retransmittion in case a packet was lost and needs to be sent again
    /// after block acknowlegment was received.
    ///
    /// - parameter configMessage: The message to be sent.
    /// - parameter destination:   The destination address.
    func send(_ configMessage: ConfigMessage, to destination: Address) {
        accessLayer.send(configMessage, to: destination)
    }
    
    /// Replies to the received message, which was sent with the given key set,
    /// with the given message.
    ///
    /// - parameter message:     The response message to be sent.
    /// - parameter destination: The destination address.
    /// - parameter keySet:      The keySet that should be used to encrypt the message.
    func reply(with message: MeshMessage, to destination: Address, using keySet: KeySet) {
        guard let primaryElement = meshNetwork?.localProvisioner?.node?.elements.first else {
            return
        }
        accessLayer.reply(with: message, from: primaryElement, to: destination, using: keySet)
    }
    
    /// Replies to the received message, which was sent with the given key set,
    /// with the given message.
    ///
    /// - parameter message:     The response message to be sent.
    /// - parameter element:     The source Element.
    /// - parameter destination: The destination address.
    /// - parameter keySet:      The keySet that should be used to encrypt the message.
    func reply(with message: MeshMessage,
               from element: Element, to destination: Address,
               using keySet: KeySet) {
        accessLayer.reply(with: message, from: element, to: destination, using: keySet)
    }
    
    /// Sends the Proxy Configuration message to the connected Proxy Node.
    ///
    /// - parameter proxyConfigurationMessage: The message to be sent.
    func send(_ message: ProxyConfigurationMessage) {
        networkLayer.send(proxyConfigurationMessage: message)
    }
    
    // MARK: - Callbacks
    
    /// Notifies the delegate about a new mesh message from the given source.
    ///
    /// - parameter message: The mesh message that was received.
    /// - parameter source:  The source Unicast Address.
    /// - parameter destination: The destination address of the message received.
    func notifyAbout(newMessage message: MeshMessage, from source: Address, to destination: Address) {
        manager.delegateQueue.async {
            self.manager.delegate?.meshNetworkManager(self.manager, didReceiveMessage: message,
                                                      sentFrom: source, to: destination)
        }
    }
    
    /// Notifies the delegate about delivering the mesh message to the given
    /// destination address.
    ///
    /// - parameter message:      The mesh message that was sent.
    /// - parameter localElement: The local element used to send the message.
    /// - parameter destination:  The destination address.
    func notifyAbout(deliveringMessage message: MeshMessage,
                     from localElement: Element, to destination: Address) {
        manager.delegateQueue.async {
            self.manager.delegate?.meshNetworkManager(self.manager, didSendMessage: message,
                                                      from: localElement, to: destination)
        }
    }
    
    /// Notifies the delegate about an error during sending the mesh message
    /// to the given destination address.
    ///
    /// - parameter error:   The error that occurred.
    /// - parameter message: The mesh message that failed to be sent.
    /// - parameter localElement: The local element used to send the message.
    /// - parameter destination:  The destination address.
    func notifyAbout(_ error: Error, duringSendingMessage message: MeshMessage,
                     from localElement: Element, to destination: Address) {
        manager.delegateQueue.async {
            self.manager.delegate?.meshNetworkManager(self.manager, failedToSendMessage: message,
                                                      from: localElement, to: destination, error: error)
        }
    }
    
}
