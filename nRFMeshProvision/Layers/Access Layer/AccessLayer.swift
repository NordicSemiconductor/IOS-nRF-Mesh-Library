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

/// The transaction object is used for Transaction Messages,
/// for example ``GenericLevelSet``.
private struct Transaction {
    /// Last used Transaction Identifier.
    private var lastTid = UInt8.random(in: UInt8.min...UInt8.max)
    /// The timestamp of the last transaction message sent.
    private var timestamp: Date = Date()
    
    /// Returns the last used TID.
    mutating func currentTid() -> UInt8 {
        timestamp = Date()
        return lastTid
    }
    
    /// Returns the next TID.
    mutating func nextTid() -> UInt8 {
        if lastTid < 255 {
            lastTid = lastTid + 1
        } else {
            lastTid = 0
        }
        timestamp = Date()
        return lastTid
    }
    
    /// Whether the transaction can be continued.
    var isActive: Bool {
        // A transaction may last up to 6 seconds.
        return timestamp.timeIntervalSinceNow > -6.0
    }
}

private class AcknowledgmentContext {
    let request: AcknowledgedMeshMessage
    let source: Address
    let destination: Address
    var timeoutTimer: BackgroundTimer?
    var retryTimer: BackgroundTimer?
    
    init(for request: AcknowledgedMeshMessage,
         sentFrom source: Address, to destination: Address,
         repeatAfter delay: TimeInterval, repeatBlock: @escaping () -> Void,
         timeout: TimeInterval, timeoutBlock: @escaping () -> Void) {
        self.request = request
        self.source = source
        self.destination = destination
        self.timeoutTimer = BackgroundTimer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            self?.invalidate()
            timeoutBlock()
        }
        initializeRetryTimer(withDelay: delay, callback: repeatBlock)
    }
    
    /// Invalidates the timers.
    func invalidate() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        retryTimer?.invalidate()
        retryTimer = nil
    }
    
    private func initializeRetryTimer(withDelay delay: TimeInterval,
                                      callback: @escaping () -> Void) {
        retryTimer?.invalidate()
        retryTimer = BackgroundTimer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] timer in
            guard let self = self, let _ = self.retryTimer else { return }
            callback()
            self.initializeRetryTimer(withDelay: timer.interval * 2, callback: callback)
        }
    }
}

internal class AccessLayer {
    private weak var networkManager: NetworkManager?
    private let meshNetwork: MeshNetwork
    private let mutex = DispatchQueue(label: "AccessLayerMutex")
    
    private var logger: LoggerDelegate? {
        return networkManager?.logger
    }
    
    /// A map of current transactions.
    ///
    /// The key is a value combined from the source and destination addresses.
    private var transactions: [UInt32 : Transaction]
    /// This array contains information about the expected acknowledgments
    /// for acknowledged mesh messages that have been sent, and for which
    /// the response has not been received yet.
    private var reliableMessageContexts: [AcknowledgmentContext]
    /// Publishers responsible for periodic publication from Models.
    private var publishers: [Model : BackgroundTimer]
    
    init(_ networkManager: NetworkManager) {
        self.networkManager = networkManager
        self.meshNetwork = networkManager.meshNetwork
        self.transactions = [:]
        self.reliableMessageContexts = []
        self.publishers = [:]
        
        reinitializePublishers()
    }
    
    deinit {
        transactions.removeAll()
        reliableMessageContexts.forEach { ack in
            ack.invalidate()
        }
        reliableMessageContexts.removeAll()
        publishers.forEach { (_, publisher) in
            publisher.invalidate()
        }
        publishers.removeAll()
    }
    
    /// Initialize periodic publishing from local Models.
    func reinitializePublishers() {
        networkManager?.meshNetwork.localElements
            .flatMap { element in element.models }
            .forEach { model in refreshPeriodicPublisher(for: model) }
    }
    
    /// This method handles the Upper Transport PDU and reads the Opcode.
    /// If the Opcode is supported, a message object is created and sent
    /// to the delegate. Otherwise, a generic MeshMessage object is created
    /// for the app to handle.
    ///
    /// - parameters:
    ///   - upperTransportPdu: The decoded Upper Transport PDU.
    ///   - keySet: The keySet that the message was encrypted with.
    func handle(upperTransportPdu: UpperTransportPdu, sentWith keySet: KeySet) {
        guard let accessPdu = AccessPdu(fromUpperTransportPdu: upperTransportPdu) else {
            return
        }
        
        // If a response to a sent request has been received, cancel the context.
        var request: AcknowledgedMeshMessage? = nil
        if upperTransportPdu.destination.address.isUnicast,
           let index = mutex.sync(execute: {
                           reliableMessageContexts.firstIndex(where: {
                               $0.source == upperTransportPdu.destination.address &&
                               $0.request.responseOpCode == accessPdu.opCode &&
                               $0.destination == upperTransportPdu.source
                           })
                       }) {
            mutex.sync {
                let context = reliableMessageContexts.remove(at: index)
                request = context.request
                context.invalidate()
            }
            logger?.i(.access, "Response \(accessPdu) received (decrypted using key: \(keySet))")
        } else {
            logger?.i(.access, "\(accessPdu) received (decrypted using key: \(keySet))")
        }
        handle(accessPdu: accessPdu, sentWith: keySet, asResponseTo: request)
    }
    
    /// Sends the ``MeshMessage`` to the given destination. The message is encrypted
    /// using given Application Key and a Network Key bound to it.
    ///
    /// Before sending, this method updates the transaction identifier (TID)
    /// for message extending ``TransactionMessage``.
    ///
    /// - parameters:
    ///   - message:        The Mesh Message to send.
    ///   - element:        The source Element.
    ///   - destination:    The destination Address. This can be any valid mesh Address.
    ///   - initialTtl:     The initial TTL (Time To Live) value of the message.
    ///                     If `nil`, the default Node TTL will be used.
    ///   - applicationKey: The Application Key to sign the message with.
    ///   - retransmit:     Whether the message is a retransmission of the
    ///                     previously sent message.
    func send(_ message: MeshMessage,
              from element: Element, to destination: MeshAddress,
              withTtl initialTtl: UInt8?, using applicationKey: ApplicationKey,
              retransmit: Bool) {
        guard let networkManager = networkManager else { return }
        // Should the TID be updated?
        var m: MeshMessage = message
        if var transactionMessage = message as? TransactionMessage, transactionMessage.tid == nil {
            // Ensure there is a transaction for our destination.
            let k = key(for: element, and: destination)
            mutex.sync {
                transactions[k] = transactions[k] ?? Transaction()
                
                // NOTE: The code below MUST use "transactions[k]!...." (instead of a temporary let
                //       as Transaction is a struct and creating temporary variable would make a copy
                //       of it instead of modifying the original object. The methods below are mutable.
                
                // Should the last transaction be continued?
                if retransmit || transactionMessage.continueTransaction, transactions[k]!.isActive {
                    transactionMessage.tid = transactions[k]!.currentTid()
                } else {
                    // If not, start a new transaction by setting a new TID value.
                    transactionMessage.tid = transactions[k]!.nextTid()
                }
            }
            m = transactionMessage
        }
        
        logger?.i(.model, "Sending \(m) from: \(element), to: \(destination.hex)")
        let pdu = AccessPdu(fromMeshMessage: m,
                            sentFrom: element.unicastAddress, to: destination,
                            userInitiated: true)
        let keySet = AccessKeySet(applicationKey: applicationKey)
        logger?.i(.access, "Sending \(pdu)")
        
        // Set timers for the acknowledged messages.
        // Acknowledged messages sent to a Group address won't await a Status.
        if message is AcknowledgedMeshMessage,
           destination.address.isUnicast {
            createReliableContext(for: pdu, sentFrom: element, withTtl: initialTtl, using: keySet)
        }
        
        networkManager.upperTransportLayer.send(pdu, withTtl: initialTtl, using: keySet)
    }
    
    /// Sends the ``ConfigMessage`` to the given destination. The message is encrypted
    /// using the Device Key which belongs to the target Node, and first
    /// Network Key known to this Node.
    ///
    /// - parameters:
    ///   - message:     The Mesh Config Message to send.
    ///   - element:     The source Element.   
    ///   - destination: The destination address. This must be a Unicast Address.
    ///   - initialTtl:  The initial TTL (Time To Live) value of the message.
    ///                  If `nil`, the default Node TTL will be used.
    func send(_ message: ConfigMessage,
              from element: Element, to destination: Address,
              withTtl initialTtl: UInt8?) {
        guard let networkManager = networkManager,
              let node = meshNetwork.node(withAddress: destination),
              var networkKey = node.networkKeys.first else {
            return
        }
        // ConfigNetKeyDelete must not be signed using the key that is being deleted.
        if let netKeyDelete = message as? ConfigNetKeyDelete,
           netKeyDelete.networkKeyIndex == networkKey.index {
            // Existence of another Network Key was checked in MeshNetworkManager.send(...).
            networkKey = node.networkKeys.last!
        }
        guard let keySet = DeviceKeySet(networkKey: networkKey, node: node) else {
            return
        }
        
        logger?.i(.foundationModel, "Sending \(message) to: \(destination.hex)")
        let pdu = AccessPdu(fromMeshMessage: message,
                            sentFrom: element.unicastAddress, to: MeshAddress(destination),
                            userInitiated: true)
        logger?.i(.access, "Sending \(pdu)")
        
        // Set timers for the acknowledged messages.
        createReliableContext(for: pdu, sentFrom: element, withTtl: initialTtl, using: keySet)
        
        networkManager.upperTransportLayer.send(pdu, withTtl: initialTtl, using: keySet)
    }
    
    /// Replies to the received message, which was sent with the given key set,
    /// with the given message.
    ///
    /// - parameters:
    ///   - origin:      The destination address of the message that the reply is for.
    ///   - message:     The response message to be sent.
    ///   - element:     The source Element.
    ///   - destination: The destination address. This must be a Unicast Address.
    ///   - keySet:      The set of keys that the message was encrypted with.
    func reply(toAcknowledgedMessageSentTo origin: Address, with message: MeshMessage,
               from element: Element, to destination: Address,
               using keySet: KeySet) {
        let category: LogCategory = message is ConfigMessage ? .foundationModel : .model
        logger?.i(category, "Replying with \(message) from: \(element), to: \(destination.hex)")
        let pdu = AccessPdu(fromMeshMessage: message,
                            sentFrom: element.unicastAddress, to: MeshAddress(destination),
                            userInitiated: false)
        
        // If the message is sent in response to a received message that was sent to
        // a Unicast Address, the node should transmit the response message with a random
        // delay between 20 and 50 milliseconds. If the message is sent in response to a
        // received message that was sent to a group address or a virtual address, the node
        // should transmit the response message with a random delay between 20 and 500
        // milliseconds. This reduces the probability of multiple nodes responding to this
        // message at exactly the same time, and therefore increases the probability of
        // message delivery rather than message collisions.
        let delay = origin.isUnicast ?
            TimeInterval.random(in: 0.020...0.050) :
            TimeInterval.random(in: 0.020...0.500)
        
        BackgroundTimer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.logger?.i(.access, "Sending \(pdu)")
            self?.networkManager?.upperTransportLayer.send(pdu, withTtl: nil, using: keySet)
        }
    }
    
    /// Cancels sending the message with the given handle.
    ///
    /// - parameter handle: The message handle.
    func cancel(_ handle: MessageHandle) {
        guard let networkManager = networkManager else { return }
        logger?.i(.access, "Cancelling messages with op code: \(handle.opCode), sent from: \(handle.source.hex) to: \(handle.destination.hex)")
        mutex.sync {
            if let index = reliableMessageContexts.firstIndex(where: {
                               $0.request.opCode == handle.opCode &&
                               $0.source == handle.source &&
                               $0.destination == handle.destination.address
                           }) {
                let context = reliableMessageContexts.remove(at: index)
                context.invalidate()
                if let localNode = networkManager.meshNetwork.localProvisioner?.node,
                   let element = localNode.element(withAddress: handle.source) {
                    networkManager.notifyAbout(error: AccessError.cancelled,
                                               duringSendingMessage: context.request,
                                               from: element, to: handle.destination)
                }
            }
        }
        networkManager.upperTransportLayer.cancel(handle)
    }
    
}

private extension AccessLayer {
    
    /// This method delivers the received PDU to all Models that support
    /// it and are subscribed to the message destination address.
    ///
    /// In general, each Access PDU should be consumed only by one Model
    /// in an Element. For example, Generic OnOff Client may send Generic
    /// OnOff Set message to the corresponding Server, which can decode it,
    /// change its state and reply with Generic OnOff Status message, that
    /// will be consumed by the Client.
    ///
    /// However, nothing stop the developers to reuse the same opcode in
    /// multiple Models. For example, there may be a Log Model on an Element,
    /// which accepts all opcodes supported by other Models on this Element,
    /// and logs the received data. The Log Models, instead of decoding the
    /// received Access PDU to Generic OnOff Set message, it may decode it as
    /// some "Message X" type.
    ///
    /// This method will make sure that each Model will receive a message
    /// decoded to the type specified in ``ModelDelegate/messageTypes`` in its
    /// ``ModelDelegate``, but the manager's delegate will be notified with
    /// the first message only.
    ///
    /// - parameters:
    ///   - accessPdu: The Access PDU received.
    ///   - keySet:    The set of keys that the message was encrypted with.
    ///   - request:   The previously sent request message, that the received
    ///                message responds to, or `nil`, if no request has
    ///                been sent.
    func handle(accessPdu: AccessPdu, sentWith keySet: KeySet,
                asResponseTo request: AcknowledgedMeshMessage?) {
        guard let networkManager = networkManager,
              let localNode = meshNetwork.localProvisioner?.node else {
            return
        }
        
        // The Access PDU is decoded into a Mesh Message.
        var newMessage: MeshMessage! = nil
        
        // If the message was encrypted using an Application Key...
        if let keySet = keySet as? AccessKeySet {
            // ..iterate through all the Elements of the local Node.
            for element in localNode.elements {
                // For each of the Models (except those that require Device Key)...
                let models = element.models.filter { !$0.requiresDeviceKey }
                for model in models {
                    // check, if the delegate is set, and it supports the opcode
                    // specified in the received Access PDU.
                    if let delegate = model.delegate,
                       let message = delegate.decode(accessPdu) {
                        // Save and log only the first decoded message (see method's comment).
                        if newMessage == nil {
                            logger?.i(.model, "\(message) received from: \(accessPdu.source.hex), to: \(accessPdu.destination.hex)")
                            newMessage = message
                        } else if type(of: message) != type(of: newMessage) {
                            // If another model's delegate decoded the same message to a different
                            // type, log this with a warning. This other type will be delivered
                            // to the delegate, but not to the global network delegate.
                            logger?.w(.model, "\(message) already decoded as \(newMessage!)")
                        }
                        // Deliver the message to the Model if it was signed with an
                        // Application Key bound to this Model and the message is
                        // targeting this Element, or the Model is subscribed to the
                        // destination address.
                        //
                        // Note:   Messages sent to .allNodes address shall be processed
                        //         only by Models on the Primary Element.
                        //         See Bluetooth Mesh Profile 1.0.1, chapter 3.4.2.4.
                        // Note 2: As the iOS implementation does not support Relay, Proxy or Friend
                        //         Features, the messages sent to those addresses shall only be
                        //         processed if the Model is explicitly subscribed to these addresses.
                        if(accessPdu.destination.address == Address.allNodes && element.isPrimary) ||
                           accessPdu.destination.address == element.unicastAddress ||
                           model.isSubscribed(to: accessPdu.destination) {
                            if model.isBoundTo(keySet.applicationKey) {
                                if let response = delegate.model(model, didReceiveMessage: message,
                                                                 sentFrom: accessPdu.source,
                                                                 to: accessPdu.destination,
                                                                 asResponseTo: request) {
                                    networkManager.reply(toAcknowledgedMessageSentTo: accessPdu.destination.address,
                                                     with: response, from: element,
                                                     to: accessPdu.source, using: keySet)
                                }
                                if delegate is SceneClientHandler {
                                    _ = networkManager.delegate?.networkDidChange()
                                }
                            } else {
                                let modelName = model.name ?? "model"
                                let element = model.parentElement!
                                logger?.w(.model, "Local \(modelName) model on \(element) not bound to key: \(keySet.applicationKey)")
                            }
                        }
                    }
                }
            }
        } else {
            // .. otherwise, the Device Key was used.
            let models = localNode.elements.flatMap { $0.models.filter { $0.supportsDeviceKey } }
            for model in models {
                // Check, if the delegate is set, and it supports the opcode
                // specified in the received Access PDU.
                if let delegate = model.delegate,
                   let message = delegate.decode(accessPdu) {
                    newMessage = message
                    // Is this message targeting the local Node?
                    if localNode.contains(elementWithAddress: accessPdu.destination.address) {
                        logger?.i(.foundationModel, "\(message) received from: \(accessPdu.source.hex)")
                        if let response = delegate.model(model, didReceiveMessage: message,
                                                         sentFrom: accessPdu.source, to: accessPdu.destination,
                                                         asResponseTo: request) {
                            networkManager.reply(toAcknowledgedMessageSentTo: accessPdu.destination.address,
                                                 with: response, from: model.parentElement!, to: accessPdu.source, using: keySet)
                            
                            // Some Config Messages require special handling.
                            handle(message)
                        }
                        _ = networkManager.delegate?.networkDidChange()
                    } else {
                        // If not, it was received by adding another Node's address to the Proxy Filter.
                        logger?.i(.foundationModel, "\(message) received from: \(accessPdu.source.hex), to: \(accessPdu.destination.hex)")
                    }
                    // A message can only be handled by a single Model, so we can break here.
                    break
                }
            }
        }
        // If the message has not been decoded and handled by any Model Delegate,
        // return it to the user as an Unknown Message.
        // To support it, create a Model Delegate and add it to local elements.
        if newMessage == nil {
            var unknownMessage = UnknownMessage(parameters: accessPdu.parameters)!
            unknownMessage.opCode = accessPdu.opCode
            newMessage = unknownMessage
        }
        networkManager.notifyAbout(newMessage: newMessage,
                                   from: accessPdu.source, to: accessPdu.destination)
    }
    
    /// This method handles selected config messages in a special way.
    func handle(_ message: MeshMessage) {
        guard let networkManager = networkManager else { return }
        // Reload Heartbeat publishing.
        if message is ConfigHeartbeatPublicationSet {
            networkManager.upperTransportLayer.refreshHeartbeatPublisher()
        }
        // Reload Model publishing.
        if message is ConfigModelPublicationSet ||
           message is ConfigModelPublicationVirtualAddressSet,
           let request = message as? ConfigAnyModelMessage,
           let localNode = meshNetwork.localProvisioner?.node,
           let element = localNode.element(withAddress: request.elementAddress),
           let model = element.model(withModelId: request.modelId) {
            refreshPeriodicPublisher(for: model)
        }
        // Handle a case when a remote Node resets the local one.
        // The ConfigResetStatus has already been sent.
        if message is ConfigNodeReset {
            networkManager.delegate?.networkDidReset()
        }
    }
    
}

private extension ModelDelegate {
    
    /// This method tries to decode the Access PDU into a Message.
    ///
    /// The Model Handler must support the opcode and specify to
    /// which type should the message be decoded.
    ///
    /// - parameter accessPdu: The Access PDU received.
    /// - returns: The decoded message, or `nil`, if the message
    ///            is not supported or invalid.
    func decode(_ accessPdu: AccessPdu) -> MeshMessage? {
        if let type = messageTypes[accessPdu.opCode] {
           return type.init(parameters: accessPdu.parameters)
        }
        return nil
    }
    
    /// This method handles the decoded message and passes it to
    /// the proper handle method, depending on its type or whether
    /// it is a response to a previously sent request.
    ///
    /// - parameters:
    ///   - model:   The local Model that received the message.
    ///   - message: The decoded message.
    ///   - source:  The Unicast Address of the Element that the message
    ///              originates from.
    ///   - destination: The destination address of the request.
    ///   - request: The request message sent previously that this message
    ///              replies to, or `nil`, if this is not a response.
    /// - returns: The response message, if the received message is an
    ///            Acknowledged Mesh Message that needs to be replied.
    func model(_ model: Model, didReceiveMessage message: MeshMessage,
               sentFrom source: Address, to destination: MeshAddress,
               asResponseTo request: AcknowledgedMeshMessage?) -> MeshResponse? {
        if let request = request {
            if let response = message as? MeshResponse {
                self.model(model, didReceiveResponse: response,
                           toAcknowledgedMessage: request,
                           from: source)
                return nil
            }
            fatalError("\(message) is not MeshResponse")
        }
        if let request = message as? AcknowledgedMeshMessage {
            do {
                return try self.model(model, didReceiveAcknowledgedMessage: request,
                                      from: source, sentTo: destination)
            } catch {
                return nil
            }
        }
        if let message = message as? UnacknowledgedMeshMessage {
            self.model(model, didReceiveUnacknowledgedMessage: message,
                       from: source, sentTo: destination)
            return nil
        }
        fatalError("\(message) is neither Acknowledged nor Unacknowledged")
    }
}

private extension AccessLayer {
    
    /// Creates a key for the Acknowledged Context map.
    ///
    /// The key consists of source and destination addresses.
    ///
    /// - parameters:
    ///   - element: The source Element.
    ///   - destination: The destination address.
    /// - returns: The key to be used in the map.
    func key(for element: Element, and destination: MeshAddress) -> UInt32 {
        return (UInt32(element.unicastAddress) << 16) | UInt32(destination.address)
    }
    
    /// Creates the context of an Acknowledged message.
    ///
    /// The context contains timers responsible for resending the message until
    /// status is received, and allows the message to be cancelled.
    ///
    /// - important: The message must be of an Acknowledged type and must be
    ///              targeting a Unicast Address; otherwise this method does nothing.
    ///
    /// - parameters:
    ///   - pdu: The PDU of the Acknowledged message.
    ///   - element: The source Element.
    ///   - initialTtl: The initial TTL with which the message is to be sent.
    ///   - keySet: The Key Set used for sending the message.
    func createReliableContext(for pdu: AccessPdu, sentFrom element: Element,
                               withTtl initialTtl: UInt8?, using keySet: KeySet) {
        guard let networkManager = networkManager else { return }
        guard let request = pdu.message as? AcknowledgedMeshMessage,
              pdu.destination.address.isUnicast else {
            return
        }
        
        /// The TTL with which the request will be sent.
        let ttl = element.parentNode?.defaultTTL ?? networkManager.networkParameters.defaultTtl
        /// The delay after which the local Element will try to resend the
        /// request. When the response isn't received after the first retry,
        /// it will try again every time doubling the last delay until the
        /// time goes out.
        let initialDelay = networkManager.networkParameters.acknowledgmentMessageInterval(forTtl: ttl, andSegmentCount: pdu.segmentsCount)
        /// The timeout before which the response should be received.
        let timeout = networkManager.networkParameters.acknowledgmentMessageTimeout
        
        let ack = AcknowledgmentContext(for: request,
            sentFrom: pdu.source, to: pdu.destination.address,
            repeatAfter: initialDelay, repeatBlock: { [weak self] in
                guard let self = self,
                      let networkManager = self.networkManager else { return }
                if !networkManager.upperTransportLayer.isReceivingResponse(from: pdu.destination.address) {
                    self.logger?.d(.access, "Resending \(pdu)")
                    networkManager.upperTransportLayer.send(pdu, withTtl: initialTtl, using: keySet)
                }
            },
            timeout: timeout, timeoutBlock: { [weak self] in
                guard let self = self,
                      let networkManager = self.networkManager else { return }
                self.logger?.w(.access, "Response to \(pdu) not received (timeout)")
                let category: LogCategory = request is AcknowledgedConfigMessage ? .foundationModel : .model
                self.logger?.w(category, "\(request) sent from: \(pdu.source.hex), to: \(pdu.destination.hex) timed out")
                self.cancel(MessageHandle(for: request,
                                          sentFrom: pdu.source, to: pdu.destination,
                                          using: networkManager))
                self.mutex.sync {
                    self.reliableMessageContexts.removeAll { $0.timeoutTimer == nil }
                }
                networkManager.notifyAbout(error: AccessError.timeout,
                                           duringSendingMessage: request,
                                           from: element, to: pdu.destination)
            }
        )
        mutex.sync {
            reliableMessageContexts.append(ack)
        }
    }
    
    /// Invalidates the current and optionally creates a new publisher
    /// that will send periodic publications, when they are set up in the
    /// Model.
    ///
    /// - parameter model: The Model for which the publisher is to be refreshed.
    func refreshPeriodicPublisher(for model: Model) {
        // Cancel current publication.
        publishers.removeValue(forKey: model)?.invalidate()
        // Ensure a new one should start...
        guard let publish = model.publish, publish.period.interval > 0,
              let composer = model.delegate?.publicationMessageComposer else {
            return
        }
        // ... and start periodic publisher.
        let publisher = BackgroundTimer.scheduledTimer(withTimeInterval: publish.period.interval,
                                                       repeats: true) { [weak self] timer in
            guard let manager = self?.networkManager else {
                timer.invalidate()
                return
            }
            manager.publish(composer(), from: model)
        }
        publishers[model] = publisher
    }
    
}
