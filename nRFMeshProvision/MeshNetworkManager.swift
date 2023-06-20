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

/// The main object responsible for managing the mesh network.
public class MeshNetworkManager: NetworkParametersProvider {
    /// Mesh Network data.
    private var meshData: MeshData
    /// The Network Layer handler.
    private var networkManager: NetworkManager?
    /// Storage to keep the app data.
    private let storage: Storage
    
    /// A queue to handle incoming and outgoing messages.
    internal let queue: DispatchQueue
    /// A queue to call delegate methods on.
    internal let delegateQueue: DispatchQueue
    
    /// The Proxy Filter state.
    public internal(set) var proxyFilter: ProxyFilter
    
    /// The delegate will receive callbacks whenever a complete
    /// Mesh Message has been received and reassembled.
    public weak var delegate: MeshNetworkDelegate?
    /// The sender object should send PDUs created by the manager
    /// using any Bearer.
    public weak var transmitter: Transmitter? {
        didSet {
            networkManager?.transmitter = transmitter
        }
    }
    /// The logger delegate will be called whenever a new log entry is created.
    public weak var logger: LoggerDelegate? {
        didSet {
            networkManager?.logger = logger
        }
    }
    
    // MARK: - Network Manager properties
    
    /// Network parameters define the mesh transmition and retransmition parameters,
    /// the default Time To Live (TTL) value and other configuration.
    ///
    /// Initially it is set to ``NetworkParameters/default``.
    ///
    /// - since: 4.0.0
    public var networkParameters: NetworkParameters = .default
    
    // MARK: - Computed properties
    
    /// The ``MeshNetwork`` object, or `nil`, if the network has not been loaded yet.
    public var meshNetwork: MeshNetwork? {
        return meshData.meshNetwork
    }
    
    /// Whether the Mesh Network has been created, or not.
    public var isNetworkCreated: Bool {
        return meshData.meshNetwork != nil
    }
    
    // MARK: - Constructors
    
    /// Initializes the Mesh Network Manager.
    ///
    /// If storage is not provided, a local file will be used instead.
    ///
    /// - important: After the manager has been initialized, the ``localElements``
    ///              property must be set . Otherwise, none of status messages will
    ///              be parsed correctly and they will be returned to the delegate
    ///              as ``UnknownMessage``s.
    ///
    /// - parameters:
    ///   - storage: The storage to use to save the network configuration.
    ///   - queue:   The `DispatchQueue` to process requests on. By default, the a global
    ///              background concurrent queue will be used.
    ///              Note, that if multiple messages are sent shortly one after another,
    ///              processing them in a concurrent queue may cause some of them to be
    ///              discarded despite the fact that they were received in the ascending
    ///              order of SeqAuth, as one with a greater SeqAuth value may be processed
    ///              before the previous one, causing the replay protection validation fail
    ///              for the latter. This library stores 2 last SeqAuth values, so if a
    ///              message with a unique SeqAuth is processed after its successor, it
    ///              will be processed correctly.
    ///   - delegateQueue: The `DispatchQueue` to call delegate methods on.
    ///                    By default the global main queue will be used.
    /// - seeAlso: ``LocalStorage``
    /// - seeAlso: ``LowerTransportLayer.checkAgainstReplayAttack(_:NetworkPdu)``
    public init(using storage: Storage = LocalStorage(),
                queue: DispatchQueue = DispatchQueue.global(qos: .background),
                delegateQueue: DispatchQueue = DispatchQueue.main) {
        self.storage = storage
        self.meshData = MeshData()
        self.queue = queue
        self.delegateQueue = delegateQueue
        self.proxyFilter = ProxyFilter(delegateQueue)
        // Only now self can be used.
        self.proxyFilter.use(with: self)
    }
    
    /// Initializes the Mesh Network Manager. It will use the ``LocalStorage`` with the given
    /// file name.
    ///
    /// - important: After the manager has been initialized, the ``localElements``
    ///              property must be set . Otherwise, none of status messages will
    ///              be parsed correctly and they will be returned to the delegate
    ///              as ``UnknownMessage``s.
    ///
    /// - parameters:
    ///   - fileName: File name to keep the configuration.
    ///   - queue:    The `DispatchQueue` to process requests on. By default, the a global
    ///               background concurrent queue will be used.
    ///               Note, that if multiple messages are sent shortly one after another,
    ///               processing them in a concurrent queue may cause some of them to be
    ///               discarded despite the fact that they were received in the ascending
    ///               order of SeqAuth, as one with a greater SeqAuth value may be processed
    ///               before the previous one, causing the replay protection validation fail
    ///               for the latter. This library stores 2 last SeqAuth values, so if a
    ///               message with a unique SeqAuth is processed after its successor, it
    ///               will be processed correctly.
    ///   - delegateQueue: The `DispatchQueue` to call delegate methods on.
    ///                    By default the global main queue will be used.
    ///
    /// - seeAlso: ``LocalStorage``
    public convenience init(using fileName: String,
                            queue: DispatchQueue = DispatchQueue.global(qos: .background),
                            delegateQueue: DispatchQueue = DispatchQueue.main) {
        self.init(using: LocalStorage(fileName: fileName),
                  queue: queue,
                  delegateQueue: delegateQueue)
    }
    
}

// MARK: - Mesh Network API

public extension MeshNetworkManager {
    
    /// Generates a new Mesh Network configuration with default values.
    ///
    /// This method will override the existing configuration, if such exists.
    /// The mesh network will contain one ``Provisioner`` with the given name
    /// and randomly generated Primary Network Key.
    ///
    /// - parameters:
    ///   - name:            The user given network name.
    ///   - provisionerName: The user given local provisioner name.
    func createNewMeshNetwork(withName name: String, by provisionerName: String) -> MeshNetwork {
        return createNewMeshNetwork(withName: name, by: Provisioner(name: provisionerName))
    }
    
    /// Generates a new Mesh Network configuration with default values.
    ///
    /// This method will override the existing configuration, if such exists.
    /// The mesh network will contain the given ``Provisioner``
    /// and randomly generated Primary Network Key.
    ///
    /// - parameters:
    ///   - name:      The user given network name.
    ///   - provisioner: The default Provisioner.
    func createNewMeshNetwork(withName name: String, by provisioner: Provisioner) -> MeshNetwork {
        let network = MeshNetwork(name: name)
        
        // Add a new default provisioner.
        try! network.add(provisioner: provisioner)
        
        meshData.meshNetwork = network
        networkManager = NetworkManager(self)
        return network
    }
    
    /// An array of Elements of the local Node.
    ///
    /// Use this property if you want to extend the capabilities of the local
    /// Node with additional Elements and Models. For example, you may add an
    /// additional Element with Generic On/Off Client Model if you support this
    /// feature in your app. Make sure there is enough addresses for all the
    /// Elements created. If a collision is found, the colliding Elements will
    /// be ignored.
    ///
    /// The mandatory Models (Configuration Server and Client and Health Server
    /// and Client) will be added automatically to the Primary Element,
    /// and should not be added explicitly.
    ///
    /// The mesh network must be created or loaded before setting this field,
    /// otherwise it has no effect.
    ///
    /// - important: This property has to be set even if no custom Models are
    ///              defined as the set operation initializes the mandatory Models.
    ///              It can be set to an empty array.
    var localElements: [Element] {
        get {
            return meshNetwork?.localElements ?? []
        }
        set {
            meshNetwork?.localElements = newValue
            networkManager?.accessLayer.reinitializePublishers()
        }
    }
}

// MARK: - Provisioning

public extension MeshNetworkManager {
    
    /// This method returns the ``ProvisioningManager`` that can be used
    /// to provision the given device.
    ///
    /// - parameter unprovisionedDevice: The device to be added to mesh network.
    /// - parameter bearer: The Provisioning Bearer to be used for sending
    ///                     provisioning PDUs.
    /// - returns: The Provisioning manager that should be used to continue
    ///            provisioning process after identification.
    /// - throws: This method throws when the mesh network has not been created,
    ///           or a Node or a Provisioner with the same UUID already exist in the network.
    func provision(unprovisionedDevice: UnprovisionedDevice,
                   over bearer: ProvisioningBearer) throws -> ProvisioningManager {
        guard let meshNetwork = meshNetwork else {
            print("Error: Mesh Network not created")
            throw MeshNetworkError.noNetwork
        }
        guard !meshNetwork.contains(nodeWithUuid: unprovisionedDevice.uuid) &&
              !meshNetwork.contains(provisionerWithUuid: unprovisionedDevice.uuid) else {
            throw MeshNetworkError.nodeAlreadyExist
        }
        return ProvisioningManager(for: unprovisionedDevice, over: bearer, in: meshNetwork)
    }
    
}

// MARK: - Send / Receive Mesh Messages

public extension MeshNetworkManager {
    
    /// This method should be called whenever a PDU has been received from the mesh
    /// network using any bearer.
    ///
    /// When a complete Mesh Message is received and reassembled, the delegate's
    /// ``MeshNetworkDelegate/meshNetworkManager(_:didReceiveMessage:sentFrom:to:)``
    /// will be called.
    ///
    /// For easier integration with ``GattBearer``, instead of calling this method,
    /// set the manager as Bearer's ``Bearer/dataDelegate``.
    ///
    /// - parameters:
    ///   - data: The PDU received.
    ///   - type: The PDU type.
    func bearerDidDeliverData(_ data: Data, ofType type: PduType) {
        guard let networkManager = networkManager else {
            return
        }
        queue.async {
            networkManager.handle(incomingPdu: data, ofType: type)
        }
    }
    
    /// This method tries to publish the given message using the
    /// publication information set in the ``Model``.
    ///
    /// If the retransmission is set to a value greater than 0, and the message
    /// is unacknowledged, this method will retransmit it number of times
    /// with the count and interval specified in the retransmission object.
    ///
    /// If the publication is not configured for the given Model, this method
    /// does nothing.
    ///
    /// - note: This method does not check whether the given Model does support
    ///         the given message. It will publish whatever message is given using
    ///         the publication configuration of the given Model.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message: The message to be sent.
    ///   - model:   The model from which to send the message.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func publish(_ message: MeshMessage, from model: Model) -> MessageHandle? {
        guard let networkManager = networkManager,
              let publish = model.publish,
              let localElement = model.parentElement,
              let _ = meshNetwork?.applicationKeys[publish.index] else {
            return nil
        }
        queue.async {
            networkManager.publish(message, from: model)
        }
        return MessageHandle(for: message, sentFrom: localElement.unicastAddress,
                             to: publish.publicationAddress.address, using: networkManager)
    }
    
    /// Encrypts the message with the Application Key and the Network Key
    /// bound to it, and sends to the given destination address.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:        The message to be sent.
    ///   - localElement:   The source Element. If `nil`, the primary
    ///                     Element will be used. The Element must belong
    ///                     to the local Provisioner's Node.
    ///   - destination:    The destination address.
    ///   - initialTtl:     The initial TTL (Time To Live) value of the message.
    ///                     If `nil`, the default Node TTL will be used.
    ///   - applicationKey: The Application Key to sign the message.
    ///   - completion:     The completion handler called when the message
    ///                     has been sent.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func send(
        _ message: MeshMessage,
        from localElement: Element? = nil, to destination: MeshAddress,
        withTtl initialTtl: UInt8? = nil,
        using applicationKey: ApplicationKey,
        completion: ((Result<Void, Error>) -> ())? = nil
    ) throws -> MessageHandle {
        guard let networkManager = networkManager,
              let meshNetwork = meshNetwork else {
            print("Error: Mesh Network not created")
            throw MeshNetworkError.noNetwork
        }
        guard let localNode = meshNetwork.localProvisioner?.node,
              let source = localElement ?? localNode.elements.first else {
            print("Error: Local Provisioner has no Unicast Address assigned")
            throw AccessError.invalidSource
        }
        guard source.parentNode == localNode else {
            print("Error: The Element does not belong to the local Node")
            throw AccessError.invalidElement
        }
        guard initialTtl == nil || initialTtl! <= 127 else {
            print("Error: TTL value \(initialTtl!) is invalid")
            throw AccessError.invalidTtl
        }
        queue.async {
            networkManager.send(message, from: source, to: destination,
                                withTtl: initialTtl, using: applicationKey,
                                completion: completion)
        }
        return MessageHandle(for: message, sentFrom: source.unicastAddress,
                             to: destination.address, using: networkManager)
    }
    
    /// Encrypts the message with the Application Key and a Network Key
    /// bound to it, and sends to the given ``Group``.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:        The message to be sent.
    ///   - localElement:   The source Element. If `nil`, the primary
    ///                     Element will be used. The Element must belong
    ///                     to the local Provisioner's Node.
    ///   - group:          The target Group.
    ///   - initialTtl:     The initial TTL (Time To Live) value of the message.
    ///                     If `nil`, the default Node TTL will be used.
    ///   - applicationKey: The Application Key to sign the message.
    ///   - completion:     The completion handler called when the message
    ///                     has been sent.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func send(
        _ message: MeshMessage,
        from localElement: Element? = nil, to group: Group,
        withTtl initialTtl: UInt8? = nil,
        using applicationKey: ApplicationKey,
        completion: ((Result<Void, Error>) -> ())? = nil
    ) throws -> MessageHandle {
        return try send(message, from: localElement, to: group.address,
                        withTtl: initialTtl, using: applicationKey,
                        completion: completion)
    }
    
    /// Encrypts the message with the first Application Key bound to the given
    /// ``Model`` and the Network Key bound to it, and sends it to the Node
    /// to which the Model belongs to.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:        The message to be sent.
    ///   - localElement:   The source Element. If `nil`, the primary
    ///                     Element will be used. The Element must belong
    ///                     to the local Provisioner's Node.
    ///   - model:          The destination Model.
    ///   - initialTtl:     The initial TTL (Time To Live) value of the message.
    ///                     If `nil`, the default Node TTL will be used.
    ///   - completion:     The completion handler called when the message
    ///                     has been sent.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the target Model does not belong to any Element, or has
    ///           no Application Key bound to it, or when
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func send(
        _ message: UnacknowledgedMeshMessage,
        from localElement: Element? = nil, to model: Model,
        withTtl initialTtl: UInt8? = nil,
        completion: ((Result<Void, Error>) -> ())? = nil
    ) throws -> MessageHandle {
        guard let element = model.parentElement else {
            print("Error: Element does not belong to a Node")
            throw AccessError.invalidDestination
        }
        guard let firstKeyIndex = model.bind.first,
              let meshNetwork = meshNetwork,
              let applicationKey = meshNetwork.applicationKeys[firstKeyIndex] else {
            print("Error: Model is not bound to any Application Key")
            throw AccessError.modelNotBoundToAppKey
        }
        return try send(message, from: localElement, to: MeshAddress(element.unicastAddress),
                        withTtl: initialTtl, using: applicationKey, completion: completion)
    }
    
    /// Encrypts the message with the common Application Key bound to both given
    /// ``Model``s and the Network Key bound to it, and sends it to the Node
    /// to which the target Model belongs to.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:      The message to be sent.
    ///   - localElement: The source Element. If `nil`, the primary
    ///                   Element will be used. The Element must belong
    ///                   to the local Provisioner's Node.
    ///   - model:        The destination Model.
    ///   - initialTtl:   The initial TTL (Time To Live) value of the message.
    ///                   If `nil`, the default Node TTL will be used.
    ///   - completion:   The completion handler called when the message
    ///                   has been sent.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local or target Model do not belong to any Element, or have
    ///           no common Application Key bound to them, or when
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func send(
        _ message: UnacknowledgedMeshMessage,
        from localModel: Model, to model: Model,
        withTtl initialTtl: UInt8? = nil,
        completion: ((Result<Void, Error>) -> ())? = nil
    ) throws -> MessageHandle {
        guard let localElement = localModel.parentElement else {
            print("Error: Source Model does not belong to an Element")
            throw AccessError.invalidSource
        }
        return try send(message, from: localElement, to: model,
                        withTtl: initialTtl, completion: completion)
    }
    
    /// Encrypts the message with the first Application Key bound to the given
    /// ``Model`` and a Network Key bound to it, and sends it to the Node
    /// to which the Model belongs to.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:        The message to be sent.
    ///   - localElement:   The source Element. If `nil`, the primary
    ///                     Element will be used. The Element must belong
    ///                     to the local Provisioner's Node.
    ///   - model:          The destination Model.
    ///   - initialTtl:     The initial TTL (Time To Live) value of the message.
    ///                     If `nil`, the default Node TTL will be used.
    ///   - completion:     The completion handler called when the response
    ///                     has been received.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the target Model does not belong to any Element, or has
    ///           no Application Key bound to it, or when
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func send(
        _ message: AcknowledgedMeshMessage,
        from localElement: Element? = nil, to model: Model,
        withTtl initialTtl: UInt8? = nil,
        completion: ((Result<MeshResponse, Error>) -> ())? = nil
    ) throws -> MessageHandle {
        guard let networkManager = networkManager,
              let meshNetwork = meshNetwork else {
            print("Error: Mesh Network not created")
            throw MeshNetworkError.noNetwork
        }
        guard let element = model.parentElement else {
            print("Error: Element does not belong to a Node")
            throw AccessError.invalidDestination
        }
        guard let firstKeyIndex = model.bind.first,
              let applicationKey = meshNetwork.applicationKeys[firstKeyIndex] else {
            print("Error: Model is not bound to any Application Key")
            throw AccessError.modelNotBoundToAppKey
        }
        guard let localNode = meshNetwork.localProvisioner?.node,
              let source = localElement ?? localNode.elements.first else {
            print("Error: Local Provisioner has no Unicast Address assigned")
            throw AccessError.invalidSource
        }
        guard source.parentNode == localNode else {
            print("Error: The Element does not belong to the local Node")
            throw AccessError.invalidElement
        }
        guard initialTtl == nil || initialTtl! <= 127 else {
            print("Error: TTL value \(initialTtl!) is invalid")
            throw AccessError.invalidTtl
        }
        queue.async {
            networkManager.send(message, from: source, to: element.unicastAddress,
                                withTtl: initialTtl, using: applicationKey,
                                completion: completion)
        }
        return MessageHandle(for: message, sentFrom: source.unicastAddress,
                             to: element.unicastAddress, using: networkManager)
    }
    
    /// Encrypts the message with the first Application Key bound to the given
    /// ``Model`` and a Network Key bound to it, and sends it to the Node
    /// to which the Model belongs to.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:        The message to be sent.
    ///   - localElement:   The source Element. If `nil`, the primary
    ///                     Element will be used. The Element must belong
    ///                     to the local Provisioner's Node.
    ///   - model:          The destination Model.
    ///   - initialTtl:     The initial TTL (Time To Live) value of the message.
    ///                     If `nil`, the default Node TTL will be used.
    ///   - completion:     The completion handler called when the response
    ///                     has been received.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the target Model does not belong to any Element, or has
    ///           no Application Key bound to it, or when
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func send<T: StaticAcknowledgedMeshMessage>(
        _ message: T,
        from localElement: Element? = nil, to model: Model,
        withTtl initialTtl: UInt8? = nil,
        completion: ((Result<T.ResponseType, Error>) -> ())? = nil
    ) throws -> MessageHandle {
        guard let networkManager = networkManager,
              let meshNetwork = meshNetwork else {
            print("Error: Mesh Network not created")
            throw MeshNetworkError.noNetwork
        }
        guard let element = model.parentElement else {
            print("Error: Element does not belong to a Node")
            throw AccessError.invalidDestination
        }
        guard let firstKeyIndex = model.bind.first,
              let applicationKey = meshNetwork.applicationKeys[firstKeyIndex] else {
            print("Error: Model is not bound to any Application Key")
            throw AccessError.modelNotBoundToAppKey
        }
        guard let localNode = meshNetwork.localProvisioner?.node,
              let source = localElement ?? localNode.elements.first else {
            print("Error: Local Provisioner has no Unicast Address assigned")
            throw AccessError.invalidSource
        }
        guard source.parentNode == localNode else {
            print("Error: The Element does not belong to the local Node")
            throw AccessError.invalidElement
        }
        guard initialTtl == nil || initialTtl! <= 127 else {
            print("Error: TTL value \(initialTtl!) is invalid")
            throw AccessError.invalidTtl
        }
        queue.async {
            networkManager.send(message, from: source, to: element.unicastAddress,
                                withTtl: initialTtl, using: applicationKey,
                                completion: completion)
        }
        return MessageHandle(for: message, sentFrom: source.unicastAddress,
                             to: element.unicastAddress, using: networkManager)
    }
    
    /// Encrypts the message with the common Application Key bound to both given
    /// ``Model``s and a Network Key bound to it, and sends it to the Node
    /// to which the target Model belongs to.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:      The message to be sent.
    ///   - localElement: The source Element. If `nil`, the primary
    ///                   Element will be used. The Element must belong
    ///                   to the local Provisioner's Node.
    ///   - model:        The destination Model.
    ///   - initialTtl:   The initial TTL (Time To Live) value of the message.
    ///                   If `nil`, the default Node TTL will be used.
    ///   - completion:   The completion handler which is called when the response
    ///                   has been received.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local or target Model do not belong to any Element, or have
    ///           no common Application Key bound to them, or when
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func send(
        _ message: AcknowledgedMeshMessage,
        from localModel: Model, to model: Model,
        withTtl initialTtl: UInt8? = nil,
        completion: ((Result<MeshResponse, Error>) -> ())? = nil
    ) throws -> MessageHandle {
        guard let localElement = localModel.parentElement else {
            print("Error: Source Model does not belong to an Element")
            throw AccessError.invalidSource
        }
        return try send(message, from: localElement, to: model,
                        withTtl: initialTtl, completion: completion)
    }
    
    /// Encrypts the message with the common Application Key bound to both given
    /// ``Model``s and a Network Key bound to it, and sends it to the Node
    /// to which the target Model belongs to.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:      The message to be sent.
    ///   - localElement: The source Element. If `nil`, the primary
    ///                   Element will be used. The Element must belong
    ///                   to the local Provisioner's Node.
    ///   - model:        The destination Model.
    ///   - initialTtl:   The initial TTL (Time To Live) value of the message.
    ///                   If `nil`, the default Node TTL will be used.
    ///   - completion:   The completion handler which is called when the response
    ///                   has been received.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local or target Model do not belong to any Element, or have
    ///           no common Application Key bound to them, or when
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func send<T: StaticAcknowledgedMeshMessage>(
        _ message: T,
        from localModel: Model, to model: Model,
        withTtl initialTtl: UInt8? = nil,
        completion: ((Result<T.ResponseType, Error>) -> ())? = nil
    ) throws -> MessageHandle {
        guard let localElement = localModel.parentElement else {
            print("Error: Source Model does not belong to an Element")
            throw AccessError.invalidSource
        }
        return try send(message, from: localElement, to: model,
                        withTtl: initialTtl, completion: completion)
    }
    
    /// Sends a Configuration Message to the Node with given destination address.
    ///
    /// The `destination` must be a Unicast Address, otherwise the method
    /// throws an ``AccessError/invalidDestination`` error.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:     The message to be sent.
    ///   - destination: The destination Unicast Address.
    ///   - initialTtl:  The initial TTL (Time To Live) value of the message.
    ///                  If `nil`, the default Node TTL will be used.
    ///   - completion:   The completion handler called when the message
    ///                   has been sent.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the destination address
    ///           is not a Unicast Address or it belongs to an unknown Node.
    ///           Error ``AccessError/cannotDelete`` is sent when trying to
    ///           delete the last Network Key on the device.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func send(_ message: UnacknowledgedConfigMessage, to destination: Address,
              withTtl initialTtl: UInt8? = nil,
              completion: ((Result<Void, Error>) -> ())? = nil) throws -> MessageHandle {
        guard let networkManager = networkManager,
              let meshNetwork = meshNetwork else {
            print("Error: Mesh Network not created")
            throw MeshNetworkError.noNetwork
        }
        guard let localProvisioner = meshNetwork.localProvisioner,
              let element = localProvisioner.node?.primaryElement else {
            print("Error: Local Provisioner has no Unicast Address assigned")
            throw AccessError.invalidSource
        }
        guard destination.isUnicast else {
            print("Error: Address: 0x\(destination.hex) is not a Unicast Address")
            throw AccessError.invalidDestination
        }
        guard let node = meshNetwork.node(withAddress: destination) else {
            print("Error: Unknown destination Node")
            throw AccessError.invalidDestination
        }
        guard let _ = node.networkKeys.first else {
            print("Fatal Error: The target Node does not have Network Key")
            throw AccessError.invalidDestination
        }
        guard let _ = node.deviceKey else {
            print("Error: Node's Device Key is unknown")
            throw AccessError.noDeviceKey
        }
        guard initialTtl == nil || initialTtl! <= 127 else {
            print("Error: TTL value \(initialTtl!) is invalid")
            throw AccessError.invalidTtl
        }
        queue.async {
            networkManager.send(message, from: element, to: destination,
                                withTtl: initialTtl, completion: completion)
        }
        return MessageHandle(for: message, sentFrom: element.unicastAddress,
                             to: destination, using: networkManager)
    }
    
    /// Sends a Configuration Message to the primary Element on the given ``Node``.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:    The message to be sent.
    ///   - node:       The destination Node.
    ///   - initialTtl: The initial TTL (Time To Live) value of the message.
    ///                 If `nil`, the default Node TTL will be used.
    ///   - completion: The completion handler which is called when the response
    ///                 has been received.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the destination address
    ///           is not a Unicast Address or it belongs to an unknown Node.
    ///           Error ``AccessError/cannotDelete`` is sent when trying to
    ///           delete the last Network Key on the device.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func send(_ message: UnacknowledgedConfigMessage, to node: Node,
              withTtl initialTtl: UInt8? = nil,
              completion: ((Result<Void, Error>) -> ())? = nil) throws -> MessageHandle {
        return try send(message, to: node.primaryUnicastAddress,
                        withTtl: initialTtl, completion: completion)
    }
    
    /// Sends Configuration Message to the Node with given destination Address.
    ///
    /// The `destination` must be a Unicast Address, otherwise the method
    /// throws an ``AccessError/invalidDestination`` error.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:     The message to be sent.
    ///   - destination: The destination Unicast Address.
    ///   - initialTtl:  The initial TTL (Time To Live) value of the message.
    ///                  If `nil`, the default Node TTL will be used.
    ///   - completion:  The completion handler which is called when the response
    ///                  has been received.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the destination address
    ///           is not a Unicast Address or it belongs to an unknown Node.
    ///           Error ``AccessError/cannotDelete`` is sent when trying to
    ///           delete the last Network Key on the device.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func send<T: AcknowledgedConfigMessage>(
        _ message: T,
        to destination: Address,
        withTtl initialTtl: UInt8? = nil,
        completion: ((Result<T.ResponseType, Error>) -> ())? = nil
    ) throws -> MessageHandle {
        guard let networkManager = networkManager,
              let meshNetwork = meshNetwork else {
            print("Error: Mesh Network not created")
            throw MeshNetworkError.noNetwork
        }
        guard let localProvisioner = meshNetwork.localProvisioner,
              let element = localProvisioner.node?.primaryElement else {
            print("Error: Local Provisioner has no Unicast Address assigned")
            throw AccessError.invalidSource
        }
        guard destination.isUnicast else {
            print("Error: Address: 0x\(destination.hex) is not a Unicast Address")
            throw AccessError.invalidDestination
        }
        guard let node = meshNetwork.node(withAddress: destination) else {
            print("Error: Unknown destination Node")
            throw AccessError.invalidDestination
        }
        guard let _ = node.networkKeys.first else {
            print("Fatal Error: The target Node does not have Network Key")
            throw AccessError.invalidDestination
        }
        guard let _ = node.deviceKey else {
            print("Error: Node's Device Key is unknown")
            throw AccessError.noDeviceKey
        }
        if message is ConfigNetKeyDelete {
            guard node.networkKeys.count > 1 else {
                print("Error: Cannot remove last Network Key")
                throw AccessError.cannotDelete
            }
        }
        guard initialTtl == nil || initialTtl! <= 127 else {
            print("Error: TTL value \(initialTtl!) is invalid")
            throw AccessError.invalidTtl
        }
        queue.async {
            networkManager.send(message, from: element, to: destination,
                                withTtl: initialTtl, completion: completion)
        }
        return MessageHandle(for: message, sentFrom: element.unicastAddress,
                             to: destination, using: networkManager)
    }
    
    /// Sends a Configuration Message to the primary Element on the given ``Node``.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameters:
    ///   - message:    The message to be sent.
    ///   - node:       The destination Node.
    ///   - initialTtl: The initial TTL (Time To Live) value of the message.
    ///                 If `nil`, the default Node TTL will be used.
    ///   - completion: The completion handler which is called when the response
    ///                 has been received.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the destination address
    ///           is not a Unicast Address or it belongs to an unknown Node.
    ///           Error ``AccessError/cannotDelete`` is sent when trying to
    ///           delete the last Network Key on the device.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func send<T: AcknowledgedConfigMessage>(
        _ message: T, to node: Node,
        withTtl initialTtl: UInt8? = nil,
        completion: ((Result<T.ResponseType, Error>) -> ())? = nil
    ) throws -> MessageHandle {
        return try send(message, to: node.primaryUnicastAddress,
                        withTtl: initialTtl, completion: completion)
    }
    
    /// Sends the Configuration Message to the primary Element of the local Node.
    ///
    /// An appropriate callback of the ``MeshNetworkDelegate`` will be called when
    /// the message has been sent successfully or a problem occured.
    ///
    /// - parameter message: The acknowledged configuration message to be sent.
    /// - throws: This method throws when the mesh network has not been created,
    ///           or the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned).
    ///           Error ``AccessError/cannotDelete`` is sent when trying to
    ///           delete the last Network Key on the device.
    /// - returns: Message handle that can be used to cancel sending.
    @discardableResult
    func sendToLocalNode<T: AcknowledgedConfigMessage>(
        _ message: T,
        completion: ((Result<T.ResponseType, Error>) -> ())? = nil
    ) throws -> MessageHandle {
        guard let meshNetwork = meshNetwork else {
            print("Error: Mesh Network not created")
            throw MeshNetworkError.noNetwork
        }
        guard let localProvisioner = meshNetwork.localProvisioner,
              let destination = localProvisioner.primaryUnicastAddress else {
            print("Error: Local Provisioner has no Unicast Address assigned")
            throw AccessError.invalidSource
        }
        return try send(message, to: destination, withTtl: 1, completion: completion)
    }
    
    /// Sends the Proxy Configuration Message to the connected Proxy Node.
    ///
    /// This method will only work if the bearer uses is GATT Proxy.
    /// The message will be encrypted and sent to the ``Transmitter``, which
    /// should deliver the PDU to the connected Node.
    ///
    /// - parameters:
    ///   - message: The Proxy Configuration message to be sent.
    ///   - initialTtl: The initial TTL (Time To Live) value of the message.
    ///                 If `nil`, the default Node TTL will be used.
    /// - throws: This method throws when the mesh network has not been created.
    func send(_ message: ProxyConfigurationMessage) throws {
        guard let networkManager = networkManager else {
            print("Error: Mesh Network not created")
            throw MeshNetworkError.noNetwork
        }
        queue.async {
            networkManager.send(message)
        }
    }
    
    /// Cancels sending the message with the given handle.
    ///
    /// - parameter messageId: The message handle.
    func cancel(_ messageId: MessageHandle) throws {
        guard let networkManager = networkManager else {
            print("Error: Mesh Network not created")
            throw MeshNetworkError.noNetwork
        }
        queue.async {
            networkManager.cancel(messageId)
        }
    }
    
}

// MARK: - Helper methods for Bearer support

extension MeshNetworkManager: BearerDataDelegate {
    
    public func bearer(_ bearer: Bearer, didDeliverData data: Data, ofType type: PduType) {
        bearerDidDeliverData(data, ofType: type)
    }
    
}

// MARK: - Handling Network Manager events

extension MeshNetworkManager: NetworkManagerDelegate {
    
    func networkManager(_ manager: NetworkManager,
                        didReceiveMessage message: MeshMessage,
                        sentFrom source: Address, to destination: Address) {
        delegateQueue.async {
            self.delegate?.meshNetworkManager(self, didReceiveMessage: message,
                                              sentFrom: source, to: destination)
        }
    }
    
    func networkManager(_ manager: NetworkManager,
                        didSendMessage message: MeshMessage,
                        from localElement: Element, to destination: Address) {
        delegateQueue.async {
            self.delegate?.meshNetworkManager(self, didSendMessage: message,
                                              from: localElement, to: destination)
        }
    }
    
    func networkManager(_ manager: NetworkManager,
                        failedToSendMessage message: MeshMessage,
                        from localElement: Element, to destination: Address,
                        error: Error) {
        delegateQueue.async {
            self.delegate?.meshNetworkManager(self, failedToSendMessage: message,
                                              from: localElement, to: destination,
                                              error: error)
        }
    }
    
    func networkDidChange() {
        _ = save()
    }
    
    func networkDidReset() {
        guard let meshNetwork = meshNetwork,
              let provisioner = meshNetwork.localProvisioner else {
            return
        }
        // Create a new network. The same local Provisioner can be used.
        // List of Local Elements is restored for the new network.
        let localElements = self.localElements
        provisioner.meshNetwork = nil
        _ = createNewMeshNetwork(withName: meshNetwork.meshName, by: provisioner)
        self.localElements = localElements
    }
    
}

// MARK: - Managing sequence numbers.

public extension MeshNetworkManager {
    
    /// This method sets the next outgoing sequence number of the given Element on local Node.
    /// This 24-bit number will be set in the next message sent by this Element. The sequence
    /// number is increased by 1 every time the Element sends a message.
    ///
    /// Mind, that the sequence number is the least significant 24-bits of a SeqAuth, where
    /// the 32 most significant bits are called IV Index. The sequence number resets to 0
    /// when the device re-enters IV Index Normal Operation after 96-144 hours of being
    /// in IV Index Update In Progress phase. The current IV Index is obtained from the
    /// Secure Network beacon upon connection to Proxy Node. Setting too low sequence
    /// number will effectively block the Element from sending messages to the network,
    /// until it will increase enough not to be discarded by other nodes.
    ///
    /// - important: This method should not be used, unless you need to reuse the same
    ///              Provisioner's Unicast Address on another device, or a device where the
    ///              app was uninstalled and reinstalled. Even then the use of it is not recommended.
    ///              The sequence number is an internal parameter of the Element and is
    ///              managed automatically by the library. Instead, each device (phone) should
    ///              use a separate Provisioner with unique set of Unicast Addresses, which
    ///              should not change on export/import.
    ///
    /// - parameters:
    ///   - sequence: The new sequence number.
    ///   - element: The Element of a Node associated with the local Provisioner.
    func setSequenceNumber(_ sequence: UInt32, forLocalElement element: Element) {
        guard let meshNetwork = meshNetwork,
              element.parentNode?.isLocalProvisioner == true,
              let defaults = UserDefaults(suiteName: meshNetwork.uuid.uuidString) else {
            return
        }
        defaults.set(sequence & 0x00FFFFFF, forKey: "S\(element.unicastAddress.hex)")
    }
    
    /// Returns the next sequence number that would be used by the given Element on local Node.
    ///
    /// - important: The sequence number is an internal parameter of an Element.
    ///              Apps should not use this method unless necessary. It is recommended
    ///              to create a new Provisioner with a unique Unicast Address instead.
    ///
    /// - parameter element: The local Element to get sequence number of.
    /// - returns: The next sequence number, or `nil` if the Element does not belong
    ///            to the local Element or the mesh network does not exist.
    func getSequenceNumber(ofLocalElement element: Element) -> UInt32? {
        guard let meshNetwork = meshNetwork,
              element.parentNode?.isLocalProvisioner == true,
              let defaults = UserDefaults(suiteName: meshNetwork.uuid.uuidString) else {
            return nil
        }
        return UInt32(defaults.integer(forKey: "S\(element.unicastAddress.hex)"))
    }
    
}

// MARK: - Save / Load

public extension MeshNetworkManager {
    
    /// Loads the Mesh Network configuration from the ``Storage`` set in the initiator
    /// of the manager.
    ///
    /// If the storage was not specified, the default local file will be used.
    ///
    /// If the storage is empty, this method tries to migrate the database from the
    /// nRF Mesh 1.0.x to the new format. This is useful when the library or the app
    /// has been updated. For fresh installs, when the storage is empty and the legacy
    /// version was not found this method returns `false`.
    ///
    /// - returns: `True` if the network settings were loaded,
    ///            `false` otherwise.
    /// - throws: If loading configuration failed.
    func load() throws -> Bool {
        if let data = storage.load() {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            meshData = try decoder.decode(MeshData.self, from: data)
            guard let meshNetwork = meshData.meshNetwork else {
                return false
            }
            
            // Restore the last IV Index. The last IV Index is stored since version 2.2.2.
            if let defaults = UserDefaults(suiteName: meshNetwork.uuid.uuidString),
               let map = defaults.object(forKey: IvIndex.indexKey) as? [String : Any],
               let ivIndex = IvIndex.fromMap(map) {
                meshNetwork.ivIndex = ivIndex
            }
            
            networkManager = NetworkManager(self)
            proxyFilter.newNetworkCreated()
            return true
        } else if let legacyState = MeshStateManager.load() {
            // The app has been updated from version 1.0.x to 2.0.
            // Time to migrate the data to the new format.
            let network = MeshNetwork(name: legacyState.name)
            try! network.add(provisioner: legacyState.provisioner,
                             withAddress: legacyState.provisionerUnicastAddress)
            let provisionerNode = network.localProvisioner!.node!
            provisionerNode.defaultTTL = legacyState.provisionerDefaultTtl
            network.ivIndex = legacyState.ivIndex
            network.networkKeys.removeAll()
            let networkKey = legacyState.networkKey
            network.add(networkKey: networkKey)
            legacyState.applicationKeys(boundTo: networkKey).forEach {
                network.add(applicationKey: $0)
            }
            legacyState.groups.forEach {
                try? network.add(group: $0)
            }
            legacyState.nodes(provisionedUsingNetworkKey: networkKey).forEach {
                try? network.add(node: $0)
            }

            // Restore the sequence number from the legacy version.
            let defaultsKey = "nRFMeshSequenceNumber"
            let oldDefaults = UserDefaults.standard
            let oldSequence = UInt32(oldDefaults.integer(forKey: defaultsKey))
            let newDefaults = UserDefaults(suiteName: network.uuid.uuidString)!
            // The version 1.0.x had only one local Element, so there is no need to
            // update sequence numbers for other possible local Elements.
            newDefaults.set(oldSequence + 1, forKey: "S\(legacyState.provisionerUnicastAddress.hex)")
            
            // Clean up.
            oldDefaults.removeObject(forKey: defaultsKey)
            MeshStateManager.cleanup()
            
            meshData.meshNetwork = network
            networkManager = NetworkManager(self)
            proxyFilter.newNetworkCreated()
            return save()
        }
        return false
    }
    
    /// Saves the Mesh Network configuration in the ``Storage`` given in the initiator
    /// of the manager.
    ///
    /// If storage was not specified, the local file will be used.
    ///
    /// - returns: `True` if the network settings was saved, `false` otherwise.
    func save() -> Bool {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try! encoder.encode(meshData)
        return storage.save(data)
    }
    
    /// Forgets the currently loaded network and saves the state.
    ///
    /// The manager gets to the state as if no ``load()`` or ``createNewMeshNetwork(withName:by:)-97wsf``
    /// was called.
    ///
    /// - returns: `True` if the network settings was saved, `false` otherwise.
    /// - since: 4.0.0
    func clear() -> Bool {
        meshData.meshNetwork = nil
        networkManager = nil
        return save()
    }
    
}

// MARK: - Export / Import
    
public extension MeshNetworkManager {
    
    /// Returns the exported Mesh Network configuration as JSON Data.
    /// The returned Data can be transferred to another application and
    /// imported. The JSON is compatible with Bluetooth Mesh Configuration Database 1.0.1 scheme.
    ///
    /// - returns: The mesh network configuration as JSON Data.
    func export() -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if #available(iOS 11.0, *) {
            encoder.outputFormatting = .sortedKeys
        }
        
        return try! encoder.encode(meshData.meshNetwork)
    }
    
    /// Returns the exported Mesh Network configuration as JSON Data.
    /// The returned Data can be transferred to another application and
    /// imported. The JSON is compatible with Bluetooth Mesh scheme.
    ///
    /// The export configuration lets exporting only a part of the
    /// network configuration. For example, when sharing the network with
    /// a guest, a home owner may create a Guest Network Key and Guest
    /// Application Key bound to it, configure Nodes in the guest room to
    /// use these keys, define guest Groups and Scenes and then export only
    /// the related part of the whole configuration. Moreover, the exported
    /// JSON may exclude all Device Keys, so that the guest cannot reconfigure
    /// the Nodes (although nothing forbids them from adding new Nodes using
    /// guest keys). When the guest leaves the room, the guest Network Key may
    /// be updated, so the guest cannot control devices afterwards.
    ///
    /// - parameter configuration: The export configuration that lets to
    ///                            narrow down what elements of the configuration
    ///                            should be exported.
    /// - returns: The mesh network configuration as JSON Data.
    func export(_ configuration: ExportConfiguration) -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if #available(iOS 11.0, *) {
            encoder.outputFormatting = .sortedKeys
        }
        
        let meshNetwork = meshData.meshNetwork?.copy(using: configuration)
        return try! encoder.encode(meshNetwork)
    }
    
    /// Imports the Mesh Network configuration from the given Data.
    /// The data must contain valid JSON with Bluetooth Mesh Configuration Database 1.0.1 scheme.
    ///
    /// - parameter data: JSON as Data.
    /// - returns: The imported mesh network.
    /// - throws: This method throws an error if import or adding
    ///           the local Provisioner failed.
    func `import`(from data: Data) throws -> MeshNetwork {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let meshNetwork = try decoder.decode(MeshNetwork.self, from: data)
        
        meshData.meshNetwork = meshNetwork

        // Restore the last IV Index. The last IV Index is stored since version 2.2.2.
        if let defaults = UserDefaults(suiteName: meshNetwork.uuid.uuidString),
           let map = defaults.object(forKey: IvIndex.indexKey) as? [String : Any],
           let ivIndex = IvIndex.fromMap(map) {
            meshNetwork.ivIndex = ivIndex
        }
        
        networkManager = NetworkManager(self)
        proxyFilter.newNetworkCreated()
        return meshNetwork
    }
    
}
