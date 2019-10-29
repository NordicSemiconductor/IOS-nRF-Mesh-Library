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
/// for example `GenericLevelSet`.
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
        self.timeoutTimer = BackgroundTimer.scheduledTimer(withTimeInterval: timeout, repeats: false) { _ in
            self.invalidate()
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
        retryTimer = BackgroundTimer.scheduledTimer(withTimeInterval: delay, repeats: false) { timer in
            guard let _ = self.retryTimer else { return }
            callback()
            self.initializeRetryTimer(withDelay: timer.interval * 2, callback: callback)
        }
    }
}

internal class AccessLayer {
    private let networkManager: NetworkManager
    private let meshNetwork: MeshNetwork
    private let mutex = DispatchQueue(label: "Mutex")
    
    private var logger: LoggerDelegate? {
        return networkManager.manager.logger
    }
    
    /// A map of current transactions.
    ///
    /// The key is a value combined from the source and destination addresses.
    private var transactions: [UInt32 : Transaction]
    /// This array contains information about the expected acknowledgments
    /// for acknowledged mesh messages that have been sent, and for which
    /// the response has not been received yet.
    private var reliableMessageContexts: [AcknowledgmentContext]
    
    init(_ networkManager: NetworkManager) {
        self.networkManager = networkManager
        self.meshNetwork = networkManager.meshNetwork!
        self.transactions = [:]
        self.reliableMessageContexts = []
    }
    
    deinit {
        transactions.removeAll()
        reliableMessageContexts.forEach { ack in
            ack.invalidate()
        }
        reliableMessageContexts.removeAll()
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
        if upperTransportPdu.destination.isUnicast,
           let index = mutex.sync(execute: {
                           reliableMessageContexts.firstIndex(where: {
                               $0.source == upperTransportPdu.destination &&
                               $0.request.responseOpCode == accessPdu.opCode
                           })
                       }) {
            mutex.sync {
                let context = reliableMessageContexts.remove(at: index)
                request = context.request
                context.invalidate()
            }
            logger?.i(.access, "Response \(accessPdu) receieved (decrypted using key: \(keySet))")
        } else {
            logger?.i(.access, "\(accessPdu) receieved (decrypted using key: \(keySet))")
        }
        handle(accessPdu: accessPdu, sentWith: keySet, asResponseTo: request)
    }
    
    /// Sends the MeshMessage to the destination. The message is encrypted
    /// using given Application Key and a Network Key bound to it.
    ///
    /// Before sending, this method updates the transaction identifier (TID)
    /// for message extending `TransactionMessage`.
    ///
    /// - parameters:
    ///   - message:        The Mesh Message to send.
    ///   - element:        The source Element.
    ///   - destination:    The destination Address. This can be any
    ///                     valid mesh Address.
    ///   - initialTtl:     The initial TTL (Time To Live) value of the message.
    ///                     If `nil`, the default Node TTL will be used.
    ///   - applicationKey: The Application Key to sign the message with.
    func send(_ message: MeshMessage,
              from element: Element, to destination: MeshAddress,
              withTtl initialTtl: UInt8?, using applicationKey: ApplicationKey) {
        // Should the TID be updated?
        var m = message
        if var tranactionMessage = message as? TransactionMessage, tranactionMessage.tid == nil {
            // Ensure there is a transaction for our destination.
            let k = key(for: element, and: destination)
            transactions[k] = transactions[k] ?? Transaction()
            // Should the last transaction be continued?
            if tranactionMessage.continueTransaction, transactions[k]!.isActive {
                tranactionMessage.tid = transactions[k]!.currentTid()
            } else {
                // If not, start a new transaction by setting a new TID value.
                tranactionMessage.tid = transactions[k]!.nextTid()
            }
            m = tranactionMessage
        }
        
        logger?.i(.model, "Sending \(m) from: \(element), to: \(destination.hex)")
        let pdu = AccessPdu(fromMeshMessage: m, sentFrom: element, to: destination,
                            userInitiated: true)
        let keySet = AccessKeySet(applicationKey: applicationKey)
        logger?.i(.access, "Sending \(pdu)")
        
        // Set timers for the acknowledged messages.
        if let _ = message as? AcknowledgedMeshMessage {
            createReliableContext(for: pdu, sentFrom: element, withTtl: initialTtl, using: keySet)
        }
        
        networkManager.upperTransportLayer.send(pdu, withTtl: initialTtl, using: keySet)
    }
    
    /// Sends the ConfigMessage to the destination. The message is encrypted
    /// using the Device Key which belongs to the target Node, and first
    /// Network Key known to this Node.
    ///
    /// - parameters:
    ///   - message:     The Mesh Config Message to send.
    ///   - destination: The destination address. This must be a Unicast Address.
    ///   - initialTtl:  The initial TTL (Time To Live) value of the message.
    ///                  If `nil`, the default Node TTL will be used.
    func send(_ message: ConfigMessage, to destination: Address,
              withTtl initialTtl: UInt8?) {
        guard let element = meshNetwork.localProvisioner?.node?.elements.first,
              let node = meshNetwork.node(withAddress: destination),
              var networkKey = node.networkKeys.first else {
            return
        }
        // ConfigNetKeyDelete must not be signed using the key that is being deleted.
        if let netKeyDelete = message as? ConfigNetKeyDelete,
           netKeyDelete.networkKeyIndex == networkKey.index {
            networkKey = node.networkKeys.last!
        }
        
        logger?.i(.foundationModel, "Sending \(message) to: \(destination.hex)")
        let pdu = AccessPdu(fromMeshMessage: message, sentFrom: element, to: MeshAddress(destination),
                            userInitiated: true)
        logger?.i(.access, "Sending \(pdu)")
        let keySet = DeviceKeySet(networkKey: networkKey, node: node)
        
        // Set timers for the acknowledged messages.
        if let _ = message as? AcknowledgedConfigMessage {
            createReliableContext(for: pdu, sentFrom: element, withTtl: initialTtl, using: keySet)
        }
        
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
    func reply(toMessageSentTo origin: Address, with message: MeshMessage,
               from element: Element, to destination: Address,
               using keySet: KeySet) {
        let category: LogCategory = message is ConfigMessage ? .foundationModel : .model
        logger?.i(category, "Replying with \(message) from: \(element), to: \(destination.hex)")
        let pdu = AccessPdu(fromMeshMessage: message, sentFrom: element, to: MeshAddress(destination),
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
        
        BackgroundTimer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            self.logger?.i(.access, "Sending \(pdu)")
            self.networkManager.upperTransportLayer.send(pdu, withTtl: nil, using: keySet)
        }
    }
    
    /// Cancels sending the message with the given handle.
    ///
    /// - parameter handle: The message handle.
    func cancel(_ handle: MessageHandle) {
        logger?.i(.access, "Cancelling messages with op code: \(handle.opCode), sent from: \(handle.source.hex) to: \(handle.destination.hex)")
        mutex.sync {
            if let index = reliableMessageContexts.firstIndex(where: {
                               $0.request.opCode == handle.opCode &&
                               $0.source == handle.source &&
                               $0.destination == handle.destination
                           }) {
                reliableMessageContexts.remove(at: index).invalidate()
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
    /// decoded to the type specified in `messageTypes` in its `ModelDelegate`,
    /// but the manager's delegate will be notified with the first message only.
    ///
    /// - parameters:
    ///   - accessPdu: The Access PDU received.
    ///   - keySet:    The set of keys that the message was encrypted with.
    ///   - request:   The previosly sent request message, that the received
    ///                message responds to, or `nil`, if no request has
    ///                been sent.
    func handle(accessPdu: AccessPdu, sentWith keySet: KeySet,
                asResponseTo request: AcknowledgedMeshMessage?) {
        guard let localNode = meshNetwork.localProvisioner?.node else {
            return
        }
        
        // The Access PDU is decoded into a Mesh Message.
        var newMessage: MeshMessage! = nil
        
        // If the message was encrypted using an Application Key...
        if let keySet = keySet as? AccessKeySet {
            // ..iterate through all the Elements of the local Node.
            for element in localNode.elements {
                // For each of the Models...
                // (except Configuration Server and Client, which use Device Key)
                for model in element.models
                    .filter({ !$0.isConfigurationServer && !$0.isConfigurationClient }) {
                    // check, if the delegate is set, and it supports the opcode
                    // specified in the received Access PDU.
                    if let delegate = model.delegate,
                       let message = delegate.decode(accessPdu) {
                        // Save and log only the first decoded message (see mehtod's comment).
                        if newMessage == nil {
                            logger?.i(.model, "\(message) received from: \(accessPdu.source.hex), to: \(accessPdu.destination.hex)")
                            newMessage = message
                        }
                        // Deliver the message to the Model if it was signed with an
                        // Application Key bound to this Model and the message is
                        // targetting this Element, or the Model is subscribed to the
                        // destination address.
                        if model.isBoundTo(keySet.applicationKey) && (
                            accessPdu.destination.address == Address.allNodes ||
                            accessPdu.destination.address == element.unicastAddress ||
                            model.isSubscribed(to: accessPdu.destination)
                           ) {
                               if let response = delegate.model(model, didReceiveMessage: message,
                                                                sentFrom: accessPdu.source,
                                                                to: accessPdu.destination,
                                                                asResponseTo: request) {
                                networkManager.reply(toMessageSentTo: accessPdu.destination.address,
                                                     with: response, from: element,
                                                     to: accessPdu.source, using: keySet)
                            }
                        }
                    }
                }
            }
        } else if let firstElement = localNode.elements.first {
            // Check Configuration Server Model.
            if let configurationServerModel = firstElement.models
                   .first(where: { $0.isConfigurationServer }),
               let delegate = configurationServerModel.delegate,
               let configMessage = delegate.decode(accessPdu) {
                newMessage = configMessage
                // Is this message targetting the local Node?
                if accessPdu.destination.address == firstElement.unicastAddress {
                    logger?.i(.foundationModel, "\(configMessage) received from: \(accessPdu.source.hex)")
                    if let response = delegate.model(configurationServerModel, didReceiveMessage: configMessage,
                                                     sentFrom: accessPdu.source, to: accessPdu.destination,
                                                     asResponseTo: request) {
                        networkManager.reply(toMessageSentTo: accessPdu.destination.address,
                                             with: response, to: accessPdu.source, using: keySet)
                    }
                    _ = networkManager.manager.save()
                } else {
                    // If not, it was received by adding another Node's address to the Proxy Filter.
                    logger?.i(.foundationModel, "\(configMessage) received from: \(accessPdu.source.hex), to: \(accessPdu.destination.hex)")
                }
            } else if let configurationClientModel = firstElement.models
                          .first(where: { $0.isConfigurationClient }),
                      let delegate = configurationClientModel.delegate,
                      let configMessage = delegate.decode(accessPdu) {
                newMessage = configMessage
                // Is this message targetting the local Node?
                if accessPdu.destination.address == firstElement.unicastAddress {
                    logger?.i(.foundationModel, "\(configMessage) received from: \(accessPdu.source.hex)")
                    if let response = delegate.model(configurationClientModel, didReceiveMessage: configMessage,
                                                     sentFrom: accessPdu.source, to: accessPdu.destination,
                                                     asResponseTo: request) {
                        networkManager.reply(toMessageSentTo: accessPdu.destination.address,
                                             with: response, to: accessPdu.source, using: keySet)
                    }
                    // Handle a case when a remote Node resets the local one.
                    // The ConfigResetStatus has already been sent.
                    if configMessage is ConfigNodeReset {
                        let localElements = meshNetwork.localElements
                        let provisioner = networkManager.manager.meshNetwork!.localProvisioner!
                        provisioner.meshNetwork = nil
                        _ = networkManager.manager.createNewMeshNetwork(withName: meshNetwork.meshName, by: provisioner)
                        networkManager.manager.localElements = localElements
                    }
                    _ = networkManager.manager.save()
                } else {
                    // If not, it was received by adding another Node's address to the Proxy Filter.
                    logger?.i(.foundationModel, "\(configMessage) received from: \(accessPdu.source.hex), to: \(accessPdu.destination.hex)")
                }
            }
        }
        if newMessage == nil {
            var unknownMessage = UnknownMessage(parameters: accessPdu.parameters)!
            unknownMessage.opCode = accessPdu.opCode
            newMessage = unknownMessage
        }
        networkManager.notifyAbout(newMessage: newMessage,
                                   from: accessPdu.source, to: accessPdu.destination.address)
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
               asResponseTo request: AcknowledgedMeshMessage?) -> MeshMessage? {
        if let request = request {
            self.model(model, didReceiveResponse: message, toAcknowledgedMessage: request, from: source)
            return nil
        } else if let request = message as? AcknowledgedMeshMessage {
            return self.model(model, didReceiveAcknowledgedMessage: request, from: source, sentTo: destination)
        } else {
            self.model(model, didReceiveUnacknowledgedMessage: message, from: source, sentTo: destination)
            return nil
        }
    }
    
}

private extension AccessLayer {
    
    func key(for element: Element, and destination: MeshAddress) -> UInt32 {
        return (UInt32(element.unicastAddress) << 16) | UInt32(destination.address)
    }
    
    func createReliableContext(for pdu: AccessPdu, sentFrom element: Element,
                               withTtl initialTtl: UInt8?, using keySet: KeySet) {
        guard let request = pdu.message as? AcknowledgedMeshMessage else {
            return
        }
        
        /// The TTL with which the request will be sent.
        let ttl = element.parentNode?.defaultTTL ?? networkManager.defaultTtl
        /// The delay after which the local Element will try to resend the
        /// request. When the response isn't received after the first retry,
        /// it will try again every time doubling the last delay until the
        /// time goes out.
        let initialDelay: TimeInterval =
            networkManager.acknowledgmentMessageInterval(ttl, pdu.segmentsCount)
        /// The timeout before which the response should be received.
        let timeout = networkManager.acknowledgmentMessageTimeout
        
        let ack = AcknowledgmentContext(for: request, sentFrom: pdu.source, to: pdu.destination.address,
            repeatAfter: initialDelay, repeatBlock: {
                if !self.networkManager.upperTransportLayer.isReceivingResponse(from: pdu.destination.address) {
                    self.logger?.d(.access, "Resending \(pdu)")
                    self.networkManager.upperTransportLayer.send(pdu, withTtl: initialTtl, using: keySet)
                }
            }, timeout: timeout, timeoutBlock: {
                self.logger?.w(.access, "Response to \(pdu) not received (timeout)")
                let category: LogCategory = request is AcknowledgedConfigMessage ? .foundationModel : .model
                self.logger?.w(category, "\(request) sent from: \(pdu.source.hex), to: \(pdu.destination.hex) timed out")
                self.cancel(MessageHandle(for: request,
                                          sentFrom: pdu.source, to: pdu.destination.address,
                                          using: self.networkManager.manager))
                self.mutex.sync {
                    self.reliableMessageContexts.removeAll(where: { $0.timeoutTimer == nil })
                }
                self.networkManager.notifyAbout(AccessError.timeout,
                                                duringSendingMessage: request,
                                                from: element, to: pdu.destination.address)
            })
        mutex.sync {
            reliableMessageContexts.append(ack)
        }
    }
    
}
