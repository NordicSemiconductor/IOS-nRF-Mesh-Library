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
    
    /// A set of addresses to which the manager is sending messages at that moment.
    ///
    /// The lower transport layer shall not transmit segmented messages for more
    /// than one Upper Transport PDU to the same destination at the same time.
    private var outgoingMessages: Set<MeshAddress> = Set()
    /// Delivery callbacks.
    ///
    /// These callbacks are set when an Unacknowledged Mesh Message is sent any address
    /// or an Acknowledged Mesh Message is sent to a Group address, which could result in
    /// 0 or more responses being received. Instead, only the delivery callback is set
    /// in such case.
    ///
    /// The key is the destination address and the value is the callback.
    /// If a message is sent without completion callback, nothing gets added to this map.
    private var deliveryCallbacks: [MeshAddress : (Result<Void, Error>) -> ()] = [:]
    /// Callbacks awaiting a mesh response for ``AcknowledgedMeshMessage`` which are not
    /// ``AcknowledgedConfigMessage``.
    ///
    /// The key is the Unicast Address of the Element from which the response is expected.
    /// The value is the pair: expected Op Code and the callback to be called.
    private var responseCallbacks: [Address : (expectedOpCode: UInt32,
                                               callback: (Result<MeshResponse, Error>) -> ())] = [:]
    /// Callbacks awaiting a mesh response for ``AcknowledgedConfigMessage``.
    ///
    /// The key is the Unicast Address of the Element from which the response is expected.
    /// The value is the pair: expected Op Code and the callback to be called.
    private var configResponseCallbacks: [Address : (expectedOpCode: UInt32,
                                                     callback: (Result<ConfigResponse, Error>) -> ())] = [:]
    /// Callbacks awaiting a mesh message.
    ///
    /// The list cpmtains the following data:
    /// - Unicast Address of the Element that is expected to send the message,
    /// - Expected Op Code,
    /// - Optional message destination (if `nil` any destination will be ,
    /// - The callback to be called when such message is received.
    private var messageCallbacks: [(source: Address,
                                    expectedOpCode: UInt32,
                                    expectedDestination: MeshAddress?,
                                    callback: (Result<MeshMessage, Error>) -> ())] = []
    /// Mutex for thread synchronization.
    private let mutex = DispatchQueue(label: "NetworkManagerMutex")
    
    // MARK: - Computed properties
    
    /// Network parameters, as given by the `networkParametersProvider`,
    /// or ``NetworkParameters/default`` if not set.
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
        accessLayer.send(message, from: localElement, to: publish.publicationAddress,
                         withTtl: ttl, using: applicationKey, retransmit: false)
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
                                          withTtl: ttl, using: applicationKey, retransmit: true)
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
    func send(_ message: MeshMessage,
              from element: Element, to destination: MeshAddress,
              withTtl initialTtl: UInt8?,
              using applicationKey: ApplicationKey) async throws {
        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation { continuation in
                let busy = mutex.sync {
                    guard !outgoingMessages.contains(destination) else {
                        continuation.resume(throwing: AccessError.busy)
                        return true
                    }
                    outgoingMessages.insert(destination)
                    deliveryCallbacks[destination] = { result in
                        continuation.resume(with: result)
                    }
                    return false
                }
                guard !busy else { return }
                accessLayer.send(message, from: element, to: destination,
                                 withTtl: initialTtl, using: applicationKey,
                                 retransmit: false)
            }
        } onCancel: {
            cancel(messageWithHandler: MessageHandle(for: message, sentFrom: element.unicastAddress,
                                                     to: destination, using: self))
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
    ///   - destination:    The destination Unicast Address.
    ///   - initialTtl:     The initial TTL (Time To Live) value of the message.
    ///                     If `nil`, the default Node TTL will be used.
    ///   - applicationKey: The Application Key to sign the message.
    func send(_ message: AcknowledgedMeshMessage,
              from element: Element, to destination: Address,
              withTtl initialTtl: UInt8?,
              using applicationKey: ApplicationKey) async throws -> MeshResponse {
        let meshAddress = MeshAddress(destination)
        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation { continuation in
                let busy = mutex.sync {
                    guard !outgoingMessages.contains(meshAddress) else {
                        continuation.resume(throwing: AccessError.busy)
                        return true
                    }
                    outgoingMessages.insert(meshAddress)
                    responseCallbacks[destination] = (
                        expectedOpCode: message.responseOpCode,
                        callback: { result in
                            continuation.resume(with: result)
                        }
                    )
                    return false
                }
                guard !busy else { return }
                accessLayer.send(message, from: element, to: meshAddress,
                                 withTtl: initialTtl, using: applicationKey,
                                 retransmit: false)
            }
        } onCancel: {
            cancel(messageWithHandler: MessageHandle(for: message, sentFrom: element.unicastAddress,
                                                     to: meshAddress, using: self))
        }
    }
    
    /// Encrypts the message with the Device Key and the first Network Key
    /// known to the target device, and sends to the given destination address.
    ///
    /// This method does not send nor return PDUs to be sent. Instead,
    /// for each created segment it calls transmitter's ``Transmitter/send(_:ofType:)``
    /// method, which should send the PDU over the air. This is in order to support
    /// retransmission in case a packet was lost and needs to be sent again
    /// after block acknowledgment was received.
    ///
    /// - parameters:
    ///   - configMessage: The message to be sent.
    ///   - element:       The source Element.
    ///   - destination:   The destination address.
    ///   - initialTtl:    The initial TTL (Time To Live) value of the message.
    ///                    If `nil`, the default Node TTL will be used.
    func send(_ configMessage: UnacknowledgedConfigMessage,
              from element: Element, to destination: Address,
              withTtl initialTtl: UInt8?) async throws {
        let meshAddress = MeshAddress(destination)
        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation { continuation in
                let busy = mutex.sync {
                    guard !outgoingMessages.contains(meshAddress) else {
                        continuation.resume(throwing: AccessError.busy)
                        return true
                    }
                    outgoingMessages.insert(meshAddress)
                    deliveryCallbacks[meshAddress] = { result in
                        continuation.resume(with: result)
                    }
                    return false
                }
                guard !busy else { return }
                accessLayer.send(configMessage, from: element, to: destination,
                                 withTtl: initialTtl)
            }
        } onCancel: {
            cancel(messageWithHandler: MessageHandle(for: configMessage, sentFrom: element.unicastAddress,
                                                     to: meshAddress, using: self))
        }
    }
    
    /// Encrypts the message with the Device Key and the first Network Key
    /// known to the target device, and sends to the given destination address.
    ///
    /// The ``ConfigNetKeyDelete`` will be signed with a different Network Key
    /// that is removing.
    ///
    /// This method does not send nor return PDUs to be sent. Instead,
    /// for each created segment it calls transmitter's ``Transmitter/send(_:ofType:)``
    /// method, which should send the PDU over the air. This is in order to support
    /// retransmission in case a packet was lost and needs to be sent again
    /// after block acknowledgment was received. 
    ///
    /// - parameters:
    ///   - configMessage: The message to be sent.
    ///   - element:       The source Element.
    ///   - destination:   The destination address.
    ///   - initialTtl:    The initial TTL (Time To Live) value of the message.
    ///                    If `nil`, the default Node TTL will be used.
    func send(_ configMessage: AcknowledgedConfigMessage,
              from element: Element, to destination: Address,
              withTtl initialTtl: UInt8?) async throws -> ConfigResponse {
        let meshAddress = MeshAddress(destination)
        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation { continuation in
                let busy = mutex.sync {
                    guard !outgoingMessages.contains(meshAddress) else {
                        continuation.resume(throwing: AccessError.busy)
                        return true
                    }
                    outgoingMessages.insert(meshAddress)
                    configResponseCallbacks[destination] = (
                        expectedOpCode: configMessage.responseOpCode,
                        callback: { result in
                            continuation.resume(with: result)
                        }
                    )
                    return false
                }
                guard !busy else { return }
                accessLayer.send(configMessage, from: element, to: destination,
                                 withTtl: initialTtl)
            }
        } onCancel: {
            cancel(messageWithHandler: MessageHandle(for: configMessage, sentFrom: element.unicastAddress,
                                                     to: meshAddress, using: self))
        }
    }
    
    /// Awaits a message with a given OpCode from the specified Unicast Address.
    ///
    /// If the destination is optional.
    ///
    /// - parameters:
    ///   - opCode: The message OpCode.
    ///   - address: The Unicast Address of the source Element.
    ///   - destination: The optional destination.
    ///   - timeout: The timeout in seconds.
    /// - returns: The received mesh message.
    /// - throws: This method may throw when the manager already awaits messages
    ///           with the same OpCode and source address or when a timeout occurred.
    func waitFor(messageWithOpCode opCode: UInt32,
                 from address: Address, to destination: MeshAddress?,
                 timeout: TimeInterval) async throws -> MeshMessage {
        let task: Task<MeshMessage, Error> = Task {
            try await withTaskCancellationHandler {
                return try await withCheckedThrowingContinuation { continuation in
                    mutex.sync {
                        // Check if there is no awaiting callback for given parameters.
                        let existingCallback = messageCallbacks.first {
                            $0.source == address &&
                            $0.expectedOpCode == opCode &&
                            ($0.expectedDestination == nil || $0.expectedDestination == destination)
                        }
                        guard existingCallback == nil else {
                            continuation.resume(throwing: AccessError.busy)
                            return
                        }
                        messageCallbacks.append((address, opCode, destination, { result in
                            continuation.resume(with: result)
                        }))
                    }
                }
            } onCancel: {
                notifyCallback(awaitingMessageWithOpCode: opCode,
                               sentFrom: address, to: destination,
                               with: .failure(AccessError.timeout))
            }
        }
        let timeoutTask = timeout == 0 ? nil : Task {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            task.cancel()
        }
        let result = try await task.value
        timeoutTask?.cancel()
        return result
    }
    
    /// Returns an async stream of messages matching given criteria.
    ///
    /// When the task in which the stream is iterated gets cancelled the cancellation
    /// handler will automatically remove the awaiting message callback and the stream
    /// will return `nil`.
    ///
    /// - important: This method is using `waitFor(...)` under the hood.
    ///              It is not possible to await both at the same time, as they share
    ///              the same instance of `messageCallbacks`.
    ///
    /// - parameters:
    ///   - opCode: The OpCode of the messages to await for.
    ///   - address: The Unicast Address of the sender.
    ///   - destination: The optional destination address of the messages.
    /// - returns: The stream of messages with given OpCode.
    func messages(withOpCode opCode: UInt32,
                  from address: Address,
                  to destination: MeshAddress?) -> AsyncStream<MeshMessage> {
        return AsyncStream {
            return try? await self.waitFor(messageWithOpCode: opCode, from: address, to: destination, timeout: 0)
        } onCancel: {
            self.cancel(awaitingMessageWithOpCode: opCode, from: address)
        }
    }
    
    /// Returns an async stream of messages matching given criteria.
    ///
    /// When the task in which the stream is iterated gets cancelled the cancellation
    /// handler will automatically remove the awaiting message callback and the stream
    /// will return `nil`.
    ///
    /// - important: This method is using `waitFor(...)` under the hood.
    ///              It is not possible to await both at the same time, as they share
    ///              the same instance of `messageCallbacks`.
    ///
    /// - parameters:
    ///   - address: The Unicast Address of the sender.
    ///   - destination: The optional destination address of the messages.
    /// - returns: The stream of messages of given type.
    func messages<T: StaticMeshMessage>(from address: Address,
                                        to destination: MeshAddress?) -> AsyncStream<T> {
        // Note: This method cannot just call the one above with T.opCode, as the return
        //       type is different. Hence, repeating the code with `as? T` added.
        return AsyncStream {
            return try? await self.waitFor(messageWithOpCode: T.opCode, from: address, to: destination, timeout: 0) as? T
        } onCancel: {
            self.cancel(awaitingMessageWithOpCode: T.opCode, from: address)
        }
    }
    
    /// Sends the Proxy Configuration message to the connected Proxy Node.
    ///
    /// - parameter message: The message to be sent.
    func send(_ message: ProxyConfigurationMessage) async {
        networkLayer.send(proxyConfigurationMessage: message)
    }
    
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
    
    /// Cancels sending the message with the given handler.
    ///
    /// - parameter handler: The message identifier.
    func cancel(messageWithHandler handler: MessageHandle) {
        accessLayer.cancel(handler)
    }
    
    /// Ńotifies a callback awaiting messages with given OpCode sent from
    /// the given Unicast Address about a cancellation.
    ///
    /// This method will send a cancellation error to the awaiting callback.
    /// This error will be received by a stream causing it to return `nil`
    /// which will finish the stream.
    ///
    /// - parameters:
    ///   - opCode: The message OpCode.
    ///   - address: The Unicast Address of the sender.
    func cancel(awaitingMessageWithOpCode opCode: UInt32, from address: Address) {
        notifyCallback(awaitingMessageWithOpCode: opCode,
                       sentFrom: address, to: nil,
                       with: .failure(CancellationError()))
    }
    
    // MARK: - Callbacks
    
    /// Notifies the delegate about a new mesh message from the given source.
    ///
    /// - parameters:
    ///   - message: The mesh message that was received.
    ///   - source:  The source Unicast Address.
    ///   - destination: The destination address of the message received.
    func notifyAbout(newMessage message: MeshMessage,
                     from source: Address, to destination: MeshAddress) {
        // Notify the callback awaiting received message.
        notifyCallback(awaitingMessageWithOpCode: message.opCode,
                       sentFrom: source, to: destination,
                       with: .success(message))
        // Notify callback awaiting a response.
        switch message {
        case let response as ConfigResponse:
            let callback: ((Result<ConfigResponse, Error>) -> ())? = mutex.sync {
                guard let (expectedOpCode, callback) = configResponseCallbacks[source],
                      expectedOpCode == response.opCode else {
                    return nil
                }
                configResponseCallbacks.removeValue(forKey: source)
                return callback
            }
            callback?(.success(response))
        case let response as MeshResponse:
            let callback: ((Result<MeshResponse, Error>) -> ())? = mutex.sync {
                guard let (expectedOpCode, callback) = responseCallbacks[source],
                      expectedOpCode == response.opCode else {
                    return nil
                }
                responseCallbacks.removeValue(forKey: source)
                return callback
            }
            callback?(.success(response))
        default:
            break
        }
        // Notify the global delegate.
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
                     from localElement: Element, to destination: MeshAddress) {
        // Notify the delivery callback.
        mutex.sync {
            _ = outgoingMessages.remove(destination)
        }
        let callback = mutex.sync {
            deliveryCallbacks.removeValue(forKey: destination)
        }
        callback?(.success(()))
        // Notify the global delegate.
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
                     from localElement: Element, to destination: MeshAddress) {
        // Notify the callback, that sending has failed.
        mutex.sync {
            _ = outgoingMessages.remove(destination)
        }
        // Notify callback awaiting a response, that sending the message has failed.0
        switch message {
        case let request as AcknowledgedConfigMessage:
            let callback: ((Result<ConfigResponse, Error>) -> ())? = mutex.sync {
                guard let (expectedOpCode, callback) = configResponseCallbacks[destination.address],
                      expectedOpCode == request.responseOpCode else {
                    return nil
                }
                configResponseCallbacks.removeValue(forKey: destination.address)
                return callback
            }
            callback?(.failure(error))
        case let request as AcknowledgedMeshMessage:
            let callback: ((Result<MeshResponse, Error>) -> ())? = mutex.sync {
                guard let (expectedOpCode, callback) = responseCallbacks[destination.address],
                      expectedOpCode == request.responseOpCode else {
                    return nil
                }
                responseCallbacks.removeValue(forKey: destination.address)
                return callback
            }
            callback?(.failure(error))
        default:
            let callback = deliveryCallbacks.removeValue(forKey: destination)
            callback?(.failure(error))
        }
        // Notify the global delegate.
        delegate?.networkManager(self, failedToSendMessage: message,
                                 from: localElement, to: destination, error: error)
    }
    
}

private extension NetworkManager {
    
    /// Notify the callback awaiting received message.
    ///
    /// - parameters:
    ///   - opCode: The message OpCode.
    ///   - address: The Unicast Address of the sender.
    ///   - destination: The optional destination. This may be set to `nil` when cancelling callbacks.
    ///   - result: The result to be returned.
    func notifyCallback(awaitingMessageWithOpCode opCode: UInt32,
                        sentFrom address: Address, to destination: MeshAddress?,
                        with result: Result<MeshMessage, Error>) {
        // Search for a callback matching given criteria.
        let messageCallback: ((Result<MeshMessage, Error>) -> ())? = mutex.sync {
            guard let index = messageCallbacks.firstIndex(where: {
                // The source Unicast Address must match.
                $0.source == address &&
                // The OpCode must match.
                $0.expectedOpCode == opCode &&
                // If the destination is set, it must either match the expected one,
                // or the expected should not be set (blind card).
                // The destination is not set when cancelling the callback.
               (destination == nil || $0.expectedDestination == nil || $0.expectedDestination == destination)
            }) else {
                return nil
            }
            // When found, remove it, as message callbacks are single use only.
            return messageCallbacks.remove(at: index).callback
        }
        // Notify the callback. It has already been removed from `messageCallbacks`.
        messageCallback?(result)
    }
    
}
