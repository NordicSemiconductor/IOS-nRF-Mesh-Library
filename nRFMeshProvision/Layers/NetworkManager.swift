/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

internal class NetworkManager {
    weak var networkParametersProvider: NetworkParametersProvider?
    weak var proxy: ProxyFilterEventHandler?
    weak var delegate: NetworkManagerDelegate?
    weak var logger: LoggerDelegate?
    weak var transmitter: Transmitter?
    
    // MARK: - Layers
    
    var networkLayer        : NetworkLayer!
    var lowerTransportLayer : LowerTransportLayer!
    var upperTransportLayer : UpperTransportLayer!
    var accessLayer         : AccessLayer!
    
    // MARK: - Properties
    
    let meshNetwork: MeshNetwork
    
    // MARK: - Computed properties
    
    var networkParameters: NetworkParameters {
        return networkParametersProvider?.networkParameters ?? .default
    }
    
    // MARK: - Implementation
    
    init(_ network: MeshNetwork) {
        meshNetwork = network
        
        networkLayer = NetworkLayer(self)
        lowerTransportLayer = LowerTransportLayer(self)
        upperTransportLayer = UpperTransportLayer(self)
        accessLayer = AccessLayer(self)
    }
    
    convenience init(_ manager: MeshNetworkManager) {
        self.init(manager.meshNetwork!)
        
        delegate = manager
        networkParametersProvider = manager
        proxy = manager.proxyFilter
        transmitter = manager.transmitter
        logger = manager.logger
    }
    
    // MARK: - Receiving messages
    
    /// This method handles the received PDU of given type.
    ///
    /// - parameters:
    ///   - pdu:  The data received.
    ///   - type: The PDU type.
    func handle(incomingPdu pdu: Data, ofType type: PduType) {
        networkLayer.handle(incomingPdu: pdu, ofType: type)
    }
    
    // MARK: - Sending messages
    
    /// Publishes the given message using the Publish information from the
    /// given Model. If publication is not set, this message does nothing.
    ///
    /// If publication retransmission is set, this method will retransmit
    /// the message specified number of times, keeping the same TID value
    /// (if applicable).
    ///
    /// - parameters:
    ///   - message: The message to be sent.
    ///   - model:   The source Model.
    func publish(_ message: MeshMessage, from model: Model) {
        guard let publish = model.publish,
              let localElement = model.parentElement,
              let applicationKey = meshNetwork.applicationKeys[publish.index] else {
            return
        }
        // Calculate the TTL to be used.
        let ttl = publish.ttl != 0xFF ?
            publish.ttl :
            localElement.parentNode?.defaultTTL ?? networkParameters.defaultTtl
        // Send the message.
        send(message, from: localElement, to: publish.publicationAddress,
             withTtl: ttl, using: applicationKey, completion: nil)
        // If retransmission was configured, start the timer that will retransmit.
        // There is no need to retransmit acknowledged messages, as they have their
        // own retransmission mechanism.
        if !(message is AcknowledgedMeshMessage) {
            var count = publish.retransmit.count
            if count > 0 {
                let interval: TimeInterval = Double(publish.retransmit.interval) / 1000
                BackgroundTimer.scheduledTimer(withTimeInterval: interval,
                                               repeats: count > 0) { [weak self] timer in
                    guard let self = self else {
                        timer.invalidate()
                        return
                    }
                    self.accessLayer.send(message, from: localElement, to: publish.publicationAddress,
                                          withTtl: ttl, using: applicationKey, retransmit: true,
                                          completion: nil)
                    count -= 1
                    if count == 0 {
                        timer.invalidate()
                    }
                }
            }
        }
    }
    
    /// Encrypts the message with the Application Key and a Network Key
    /// bound to it, and sends to the given destination address.
    ///
    /// This method does not send nor return PDUs to be sent. Instead,
    /// for each created segment it calls transmitter's ``Transmitter/send(_:ofType:)``
    /// method, which should send the PDU over the air. This is in order to support
    /// retransmission in case a packet was lost and needs to be sent again
    /// after block acknowledgment was received.
    ///
    /// - parameters:
    ///   - message:        The message to be sent.
    ///   - element:        The source Element.
    ///   - destination:    The destination address.
    ///   - initialTtl:     The initial TTL (Time To Live) value of the message.
    ///                     If `nil`, the default Node TTL will be used.
    ///   - applicationKey: The Application Key to sign the message.
    ///   - completion:     The completion handler called when the message was sent.
    func send(_ message: MeshMessage,
              from element: Element, to destination: MeshAddress,
              withTtl initialTtl: UInt8?,
              using applicationKey: ApplicationKey,
              completion: ((Result<Void, Error>) -> ())?) {
        accessLayer.send(message, from: element, to: destination,
                         withTtl: initialTtl, using: applicationKey,
                         retransmit: false, completion: completion)
    }
    
    /// Encrypts the message with the Application Key and a Network Key
    /// bound to it, and sends to the given destination address.
    ///
    /// This method does not send nor return PDUs to be sent. Instead,
    /// for each created segment it calls transmitter's ``Transmitter/send(_:ofType:)``
    /// method, which should send the PDU over the air. This is in order to support
    /// retransmission in case a packet was lost and needs to be sent again
    /// after block acknowledgment was received.
    ///
    /// - parameters:
    ///   - message:        The message to be sent.
    ///   - element:        The source Element.
    ///   - destination:    The destination Unicast Address.
    ///   - initialTtl:     The initial TTL (Time To Live) value of the message.
    ///                     If `nil`, the default Node TTL will be used.
    ///   - applicationKey: The Application Key to sign the message.
    ///   - completion:     The completion handler with the response.
    func send(_ message: AcknowledgedMeshMessage,
              from element: Element, to destination: Address,
              withTtl initialTtl: UInt8?,
              using applicationKey: ApplicationKey,
              completion: ((Result<MeshResponse, Error>) -> ())?) {
        accessLayer.send(message, from: element, to: destination,
                         withTtl: initialTtl, using: applicationKey,
                         retransmit: false, completion: completion)
    }
    
    /// Encrypts the message with the Device Key and the first Network Key
    /// known to the target device, and sends to the given destination address.
    ///
    /// The ``ConfigNetKeyDelete`` will be signed with a different Network Key
    /// that is being removed.
    ///
    /// This method does not send nor return PDUs to be sent. Instead,
    /// for each created segment it calls transmitter's ``Transmitter/send(_:ofType:)``
    /// method, which should send the PDU over the air. This is in order to support
    /// retransmission in case a packet was lost and needs to be sent again
    /// after block acknowledgment was received. 
    ///
    /// - parameters:
    ///   - configMessage: The message to be sent.
    ///   - destination:   The destination address.
    ///   - initialTtl:    The initial TTL (Time To Live) value of the message.
    ///                    If `nil`, the default Node TTL will be used.
    ///   - completion:    The completion handler with the response.
    func send(_ configMessage: AcknowledgedConfigMessage, to destination: Address,
              withTtl initialTtl: UInt8?,
              completion: ((Result<ConfigResponse, Error>) -> ())?) {
        accessLayer.send(configMessage, to: destination,
                         withTtl: initialTtl, completion: completion)
    }
    
    /// Replies to the received message, which was sent with the given key set,
    /// with the given message. The message will be sent from the local
    /// Primary Element.
    ///
    /// - parameters:
    ///   - origin:      The destination address of the message that the reply is for.
    ///   - message:     The response message to be sent.
    ///   - destination: The destination address. This must be a Unicast Address.
    ///   - keySet:      The keySet that should be used to encrypt the message.
    // TODO: Remove?
//    func reply(toAcknowledgedMessageSentTo origin: Address, with message: MeshResponse,
//               to destination: Address, using keySet: KeySet) {
//        guard let primaryElement = meshNetwork.localProvisioner?.node?.elements.first else {
//            return
//        }
//        accessLayer.reply(toAcknowledgedMessageSentTo: origin, with: message,
//                          from: primaryElement, to: destination, using: keySet)
//    }
    
    /// Replies to the received message, which was sent with the given key set,
    /// with the given message.
    ///
    /// - parameters:
    ///   - origin:      The destination address of the message that the reply is for.
    ///   - message:     The response message to be sent.
    ///   - element:     The source Element.
    ///   - destination: The destination address. This must be a Unicast Address.
    ///   - keySet:      The keySet that should be used to encrypt the message.
    func reply(toAcknowledgedMessageSentTo origin: Address, with message: MeshResponse,
               from element: Element, to destination: Address,
               using keySet: KeySet) {
        accessLayer.reply(toAcknowledgedMessageSentTo: origin, with: message,
                          from: element, to: destination, using: keySet)
    }
    
    /// Sends the Proxy Configuration message to the connected Proxy Node.
    ///
    /// - parameter message: The message to be sent.
    func send(_ message: ProxyConfigurationMessage) {
        networkLayer.send(proxyConfigurationMessage: message)
    }
    
    /// Cancels sending the message with the given handler.
    ///
    /// - parameter handler: The message identifier.
    func cancel(_ handler: MessageHandle) {
        accessLayer.cancel(handler)
    }
    
    // MARK: - Callbacks
    
    /// Notifies the delegate about a new mesh message from the given source.
    ///
    /// - parameters:
    ///   - message: The mesh message that was received.
    ///   - source:  The source Unicast Address.
    ///   - destination: The destination address of the message received.
    func notifyAbout(newMessage message: MeshMessage,
                     from source: Address, to destination: Address) {
        delegate?.networkManager(self, didReceiveMessage: message,
                                 sentFrom: source, to: destination)
    }
    
    /// Notifies the delegate about delivering the mesh message to the given
    /// destination address.
    ///
    /// - parameters:
    ///   - message:      The mesh message that was sent.
    ///   - localElement: The local element used to send the message.
    ///   - destination:  The destination address.
    func notifyAbout(deliveringMessage message: MeshMessage,
                     from localElement: Element, to destination: Address) {
        delegate?.networkManager(self, didSendMessage: message,
                                 from: localElement, to: destination)
    }
    
    /// Notifies the delegate about an error during sending the mesh message
    /// to the given destination address.
    ///
    /// - parameters:
    ///   - error:   The error that occurred.
    ///   - message: The mesh message that failed to be sent.
    ///   - localElement: The local element used to send the message.
    ///   - destination:  The destination address.
    func notifyAbout(error: Error, duringSendingMessage message: MeshMessage,
                     from localElement: Element, to destination: Address) {
        delegate?.networkManager(self, failedToSendMessage: message,
                                 from: localElement, to: destination, error: error)
    }
    
}
