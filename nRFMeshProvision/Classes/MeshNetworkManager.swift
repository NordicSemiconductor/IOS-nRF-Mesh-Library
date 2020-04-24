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

public class MeshNetworkManager {
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
    public internal(set) var proxyFilter: ProxyFilter?
    
    /// The logger delegate will be called whenever a new log entry is created.
    public weak var logger: LoggerDelegate?
    /// The delegate will receive callbacks whenever a complete
    /// Mesh Message has been received and reassembled.
    public weak var delegate: MeshNetworkDelegate?
    /// The sender object should send PDUs created by the manager
    /// using any Bearer.
    public weak var transmitter: Transmitter?
    
    // MARK: - Network Manager properties
    
    /// The Default TTL will be used for sending messages, if the value has
    /// not been set in the Provisioner's Node. By default it is set to 5,
    /// which is a reasonable value. The TTL shall be in range 2...127.
    public var defaultTtl: UInt8 = 5
    /// The timeout after which an incomplete segmented message will be
    /// abandoned. The timer is restarted each time a segment of this
    /// message is received.
    ///
    /// The incomplete timeout should be set to at least 10 seconds.
    public var incompleteMessageTimeout: TimeInterval = 10.0
    /// The amount of time after which the lower transport layer sends a
    /// Segment Acknowledgment message after receiving a segment of a
    /// multi-segment message where the destination is a Unicast Address
    /// of the Provisioner's Element.
    ///
    /// The acknowledgment timer shall be set to a minimum of
    /// 150 + 50 * TTL milliseconds. The TTL dependent part is added
    /// automatically, and this value shall specify only the constant part.
    public var acknowledgmentTimerInterval: TimeInterval = 0.150
    /// The time within which a Segment Acknowledgment message is
    /// expected to be received after a segment of a segmented message has
    /// been sent. When the timer is fired, the non-acknowledged segments
    /// are repeated, at most `retransmissionLimit` times.
    ///
    /// The transmission timer shall be set to a minimum of
    /// 200 + 50 * TTL milliseconds. The TTL dependent part is added
    /// automatically, and this value shall specify only the constant part.
    ///
    /// If the bearer is using GATT, it is recommended to set the transmission
    /// interval longer than the connection interval, so that the acknowledgment
    /// had a chance to be received.
    public var transmissionTimerInteral: TimeInterval = 0.200
    /// Number of times a non-acknowledged segment of a segmented message
    /// will be retransmitted before the message will be cancelled.
    ///
    /// The limit may be decreased with increasing of `transmissionTimerInterval`
    /// as the target Node has more time to reply with the Segment
    /// Acknowledgment message.
    public var retransmissionLimit: Int = 5
    /// If the Element does not receive a response within a period of time known
    /// as the acknowledged message timeout, then the Element may consider the
    /// message has not been delivered, without sending any additional messages.
    ///
    /// The `meshNetworkManager(_:failedToSendMessage:from:to:error)`
    /// callback will be called on timeout.
    ///
    /// The acknowledged message timeout should be set to a minimum of 30 seconds.
    public var acknowledgmentMessageTimeout: TimeInterval = 30.0
    /// The base time after which the acknowledgmed message will be repeated.
    ///
    /// The repeat timer will be set to the base time + 50 * TTL milliseconds +
    /// 50 * segment count. The TTL and segment count dependent parts are added
    /// automatically, and this value shall specify only the constant part.
    public var acknowledgmentMessageInterval: TimeInterval = 2.0
    /// According to Bluetooth Mesh Profile 1.0.1, section 3.10.5, if the IV Index of the mesh
    /// network increased by more than 42 since the last connection (which can take at least
    /// 48 weeks), the Node should be reprovisioned. However, as this library can be used to
    /// provision other Nodes, it should not be blocked from sending messages to the network
    /// only because the phone wasn't connected to the network for that time. This flag can
    /// disable this check, effectively allowing such connection.
    ///
    /// The same can be achieved by clearing the app data (uninstalling and reinstalling the
    /// app) and importing the mesh network. With no "previous" IV Index, the library will
    /// accept any IV Index received in the Secure Network beacon upon connection to the
    /// GATT Proxy Node.
    public var allowIvIndexRecoveryOver42: Bool = false
    /// IV Update Test Mode enables efficient testing of the IV Update procedure.
    /// The IV Update test mode removes the 96-hour limit; all other behavior of the device
    /// are unchanged.
    ///
    /// - seeAlso: Bluetooth Mesh Profile 1.0.1, section 3.10.5.1.
    public var ivUpdateTestMode: Bool = false
    
    // MARK: - Computed properties
    
    /// Returns the MeshNetwork object.
    public var meshNetwork: MeshNetwork? {
        return meshData.meshNetwork
    }
    
    /// Returns `true` if Mesh Network has been created, `false` otherwise.
    public var isNetworkCreated: Bool {
        return meshData.meshNetwork != nil
    }
    
    // MARK: - Constructors
    
    /// Initializes the MeshNetworkManager.
    ///
    /// If storage is not provided, a local file will be used instead.
    ///
    /// - important: Aafter the manager has been initialized, the
    ///              `localElements` property must be set . Otherwise,
    ///              none of status messages will be parsed correctly
    ///              and they will be returned to the delegate as
    ///              `UnknownMessage`s.
    ///
    /// - parameters:
    ///   - storage: The storage to use to save the network configuration.
    ///   - queue: The DispatQueue to process reqeusts on. By default
    ///            the a global background queue will be used.
    ///   - delegateQueue: The DispatQueue to call delegate methods on.
    ///                    By default the global main queue will be used.
    /// - seeAlso: `LocalStorage`
    public init(using storage: Storage = LocalStorage(),
                queue: DispatchQueue = DispatchQueue.global(qos: .background),
                delegateQueue: DispatchQueue = DispatchQueue.main) {
        self.storage = storage
        self.meshData = MeshData()
        self.queue = queue
        self.delegateQueue = delegateQueue
    }
    
    /// Initializes the MeshNetworkManager. It will use the `LocalStorage`
    /// with the given file name.
    ///
    /// - parameter fileName: File name to keep the configuration.
    /// - seeAlso: `LocalStorage`
    public convenience init(using fileName: String) {
        self.init(using: LocalStorage(fileName: fileName))
    }
    
}

// MARK: - Mesh Network API

public extension MeshNetworkManager {
    
    /// Generates a new Mesh Network configuration with default values.
    /// This method will override the existing configuration, if such exists.
    /// The mesh network will contain one Provisioner with given name.
    ///
    /// Network Keys and Application Keys must be added manually
    /// using `add(networkKey:name)` and `add(applicationKey:name)`.
    ///
    /// - parameters:
    ///   - name:            The user given network name.
    ///   - provisionerName: The user given local provisioner name.
    func createNewMeshNetwork(withName name: String, by provisionerName: String) -> MeshNetwork {
        return createNewMeshNetwork(withName: name, by: Provisioner(name: provisionerName))
    }
    
    /// Generates a new Mesh Network configuration with default values.
    /// This method will override the existing configuration, if such exists.
    /// The mesh network will contain one Provisioner with given name.
    ///
    /// Network Keys and Application Keys must be added manually
    /// using `add(networkKey:name)` and `add(applicationKey:name)`.
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
        proxyFilter = ProxyFilter(self)
        return network
    }
    
    /// An array of Elements of the local Node.
    ///
    /// Use this property if you want to extend the capabilities of the local
    /// Node with additional Elements and Models. For example, you may add an
    /// additional Element with Generic On/Off Client Model if you support this
    /// feature in your app. Make sure there is enough addresses for all the
    /// Elements created. If a collision is found, the coliding Elements will
    /// be ignored.
    ///
    /// The Element with all mandatory Models (Configuration Server and Client
    /// and Health Server and Client) will be added automatically at index 0,
    /// and should be skipped when setting.
    ///
    /// The mesh network must be created or loaded before setting this field,
    /// otherwise it has no effect.
    var localElements: [Element] {
        get {
            return meshNetwork?.localElements ?? []
        }
        set {
            meshNetwork?.localElements = newValue
        }
    }
}

// MARK: - Provisioning

public extension MeshNetworkManager {
    
    /// This method returns the Provisioning Manager that can be used
    /// to provision the given device.
    ///
    /// - parameter unprovisionedDevice: The device to be added to mes network.
    /// - parameter bearer: The Provisioning Bearer to be used for sending
    ///                     provisioning PDUs.
    /// - returns: The Provisioning manager that should be used to continue
    ///            provisioning process after identification.
    /// - throws: This method throws when the mesh network has not been created.
    func provision(unprovisionedDevice: UnprovisionedDevice,
                   over bearer: ProvisioningBearer) throws -> ProvisioningManager {
        guard let meshNetwork = meshNetwork else {
            print("Error: Mesh Network not created")
            throw MeshNetworkError.noNetwork
        }
        return ProvisioningManager(for: unprovisionedDevice, over: bearer, in: meshNetwork)
    }
    
}

// MARK: - Send / Receive Mesh Messages

public extension MeshNetworkManager {
    
    /// This method should be called whenever a PDU has been received
    /// from the mesh network using any bearer.
    /// When a complete Mesh Message is received and reassembled, the
    /// delegate's `meshNetwork(:didDeliverMessage:from)` will be called.
    ///
    /// For easier integration with Bearers use
    /// `bearer(didDeliverData:ofType)` instead, and set the manager
    /// as Bearer's `dataDelegate`.
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
    /// publication information set in the Model.
    ///
    /// - parameters:
    ///   - message:    The message to be sent.
    ///   - model:      The model from which to send the message.
    ///   - initialTtl: The initial TTL (Time To Live) value of the message.
    ///                 If `nil`, the default Node TTL will be used.
    func publish(_ message: MeshMessage, fromModel model: Model,
                 withTtl initialTtl: UInt8? = nil) -> MessageHandle? {
        guard let publish = model.publish,
            let localElement = model.parentElement,
            let applicationKey = meshNetwork?.applicationKeys[publish.index] else {
            return nil
        }
        return try? send(message, from: localElement, to: publish.publicationAddress,
                         withTtl: initialTtl, using: applicationKey)
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
    /// A `delegate` method will be called when the message has been sent,
    /// delivered, or failed to be sent.
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
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node.
    /// - returns: Message handle that can be used to cancel sending.
    func send(_ message: MeshMessage,
              from localElement: Element? = nil, to destination: MeshAddress,
              withTtl initialTtl: UInt8? = nil, using applicationKey: ApplicationKey) throws -> MessageHandle {
        guard let networkManager = networkManager, let meshNetwork = meshNetwork else {
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
        guard initialTtl == nil || initialTtl == 0 || (2...127).contains(initialTtl!) else {
            print("Error: TTL value \(initialTtl!) is invalid")
            throw AccessError.invalidTtl
        }
        queue.async {
            networkManager.send(message, from: source, to: destination,
                                withTtl: initialTtl, using: applicationKey)
        }
        return MessageHandle(for: message, sentFrom: source.unicastAddress,
                         to: destination.address, using: self)
    }
    
    /// Encrypts the message with the Application Key and a Network Key
    /// bound to it, and sends to the given Group.
    ///
    /// A `delegate` method will be called when the message has been sent,
    /// or failed to be sent.
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
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node.
    /// - returns: Message handle that can be used to cancel sending.
    func send(_ message: MeshMessage,
              from localElement: Element? = nil, to group: Group,
              withTtl initialTtl: UInt8? = nil, using applicationKey: ApplicationKey) throws -> MessageHandle {
        return try send(message, from: localElement, to: group.address,
                        withTtl: initialTtl, using: applicationKey)
    }
    
    /// Encrypts the message with the first Application Key bound to the given
    /// Model and a Network Key bound to it, and sends it to the Node
    /// to which the Model belongs to.
    ///
    /// A `delegate` method will be called when the message has been sent,
    /// delivered, or fail to be sent.
    ///
    /// - parameters:
    ///   - message:       The message to be sent.
    ///   - localElement:  The source Element. If `nil`, the primary
    ///                    Element will be used. The Element must belong
    ///                    to the local Provisioner's Node.
    ///   - model:         The destination Model.
    ///   - initialTtl:    The initial TTL (Time To Live) value of the message.
    ///                    If `nil`, the default Node TTL will be used.
    ///   - applicationKey: The Application Key to sign the message.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the target Model does not belong to any Element, or has
    ///           no Application Key bound to it, or when
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node.
    /// - returns: Message handle that can be used to cancel sending.
    func send(_ message: MeshMessage,
              from localElement: Element? = nil, to model: Model,
              withTtl initialTtl: UInt8? = nil) throws -> MessageHandle {
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
                        withTtl: initialTtl, using: applicationKey)
    }
    
    /// Encrypts the message with the common Application Key bound to both given
    /// Models and a Network Key bound to it, and sends it to the Node
    /// to which the target Model belongs to.
    ///
    /// A `delegate` method will be called when the message has been sent,
    /// delivered, or fail to be sent.
    ///
    /// - parameters:
    ///   - message:      The message to be sent.
    ///   - localElement: The source Element. If `nil`, the primary
    ///                   Element will be used. The Element must belong
    ///                   to the local Provisioner's Node.
    ///   - model:        The destination Model.
    ///   - initialTtl:   The initial TTL (Time To Live) value of the message.
    ///                   If `nil`, the default Node TTL will be used.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local or target Model do not belong to any Element, or have
    ///           no common Application Key bound to them, or when
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the given local Element
    ///           does not belong to the local Node.
    /// - returns: Message handle that can be used to cancel sending.
    func send(_ message: MeshMessage,
              from localModel: Model, to model: Model,
              withTtl initialTtl: UInt8? = nil) throws -> MessageHandle {
        guard let meshNetwork = meshNetwork else {
            print("Error: Mesh Network not created")
            throw MeshNetworkError.noNetwork
        }
        guard let element = model.parentElement else {
            print("Error: Element does not belong to a Node")
            throw AccessError.invalidDestination
        }
        guard let localElement = localModel.parentElement else {
            print("Error: Source Model does not belong to an Element")
            throw AccessError.invalidSource
        }
        guard let commonKeyIndex = model.bind.first(where: { localModel.bind.contains($0) }),
              let applicationKey = meshNetwork.applicationKeys[commonKeyIndex] else {
            print("Error: Models are not bound to any common Application Key")
            throw AccessError.modelNotBoundToAppKey
        }
        return try send(message, from: localElement, to: MeshAddress(element.unicastAddress),
                        withTtl: initialTtl, using: applicationKey)
    }
    
    /// Sends Configuration Message to the Node with given destination Address.
    /// The `destination` must be a Unicast Address, otherwise the method
    /// does nothing.
    ///
    /// A `delegate` method will be called when the message has been sent,
    /// delivered, or fail to be sent.
    ///
    /// - parameters:
    ///   - message:     The message to be sent.
    ///   - destination: The destination Unicast Address.
    ///   - initialTtl:  The initial TTL (Time To Live) value of the message.
    ///                  If `nil`, the default Node TTL will be used.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the destination address
    ///           is not a Unicast Address or it belongs to an unknown Node.
    ///           Error `AccessError.cannotDelete` is sent when trying to
    ///           delete the last Network Key on the device.
    /// - returns: Message handle that can be used to cancel sending.
    func send(_ message: ConfigMessage, to destination: Address,
              withTtl initialTtl: UInt8? = nil) throws -> MessageHandle {
        guard let networkManager = networkManager, let meshNetwork = meshNetwork else {
            print("Error: Mesh Network not created")
            throw MeshNetworkError.noNetwork
        }
        guard let localProvisioner = meshNetwork.localProvisioner,
              let source = localProvisioner.unicastAddress else {
            print("Error: Local Provisioner has no Unicast Address assigned")
            throw AccessError.invalidSource
        }
        guard destination.isUnicast else {
            print("Error: Address: 0x\(destination.hex) is not a Unicast Address")
            throw MeshMessageError.invalidAddress
        }
        guard let node = meshNetwork.node(withAddress: destination) else {
            print("Error: Unknown destination Node")
            throw AccessError.invalidDestination
        }
        guard let _ = node.networkKeys.first else {
            print("Fatal Error: The target Node does not have Network Key")
            throw AccessError.invalidDestination
        }
        if message is ConfigNetKeyDelete {
            guard node.networkKeys.count > 1 else {
                print("Error: Cannot remove last Network Key")
                throw AccessError.cannotDelete
            }
        }
        guard initialTtl == nil || initialTtl == 0 || (2...127).contains(initialTtl!) else {
            print("Error: TTL value \(initialTtl!) is invalid")
            throw AccessError.invalidTtl
        }
        queue.async {
            networkManager.send(message, to: destination, withTtl: initialTtl)
        }
        return MessageHandle(for: message, sentFrom: source,
                         to: destination, using: self)
    }
    
    /// Sends Configuration Message to the given Node.
    ///
    /// A `delegate` method will be called when the message has been sent,
    /// delivered, or fail to be sent.
    ///
    /// - parameters:
    ///   - message: The message to be sent.
    ///   - node:    The destination Node.
    ///   - initialTtl: The initial TTL (Time To Live) value of the message.
    ///                 If `nil`, the default Node TTL will be used.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the destination address
    ///           is not a Unicast Address or it belongs to an unknown Node.
    /// - returns: Message handle that can be used to cancel sending.
    func send(_ message: ConfigMessage, to node: Node,
              withTtl initialTtl: UInt8? = nil) throws -> MessageHandle {
        return try send(message, to: node.unicastAddress, withTtl: initialTtl)
    }
    
    /// Sends Configuration Message to the given Node.
    ///
    /// A `delegate` method will be called when the message has been sent,
    /// delivered, or fail to be sent.
    ///
    /// - parameters:
    ///   - message: The message to be sent.
    ///   - element: The destination Element.
    ///   - initialTtl: The initial TTL (Time To Live) value of the message.
    ///                 If `nil`, the default Node TTL will be used.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the target Element does not
    ///           belong to any known Node.
    /// - returns: Message handle that can be used to cancel sending.
    func send(_ message: ConfigMessage, to element: Element,
              withTtl initialTtl: UInt8? = nil) throws -> MessageHandle {
        guard let node = element.parentNode else {
            print("Error: Element does not belong to a Node")
            throw AccessError.invalidDestination
        }
        return try send(message, to: node, withTtl: initialTtl)
    }
    
    /// Sends Configuration Message to the given Node.
    ///
    /// A `delegate` method will be called when the message has been sent,
    /// delivered, or fail to be sent.
    ///
    /// - parameters:
    ///   - message: The message to be sent.
    ///   - model:   The destination Model.
    ///   - initialTtl: The initial TTL (Time To Live) value of the message.
    ///                 If `nil`, the default Node TTL will be used.
    /// - throws: This method throws when the mesh network has not been created,
    ///           the local Node does not have configuration capabilities
    ///           (no Unicast Address assigned), or the target Element does
    ///           not belong to any known Node.
    /// - returns: Message handle that can be used to cancel sending.
    func send(_ message: ConfigMessage, to model: Model,
              withTtl initialTtl: UInt8? = nil) throws -> MessageHandle {
        guard let element = model.parentElement else {
            print("Error: Model does not belong to an Element")
            throw AccessError.invalidDestination
        }
        return try send(message, to: element, withTtl: initialTtl)
    }
    
    /// Sends the Proxy Configuration Message to the connected Proxy Node.
    ///
    /// This method will only work if the bearer uses is GATT Proxy.
    /// The message will be encrypted and sent to the `transported`, which
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
    
    /// Cancels sending the message with the given identifier.
    ///
    /// - parameter messageId: The message identifier.
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
    
    /// Loads the Mesh Network configuration from the storage.
    /// If storage is not given, a local file will be used.
    ///
    /// If the storage is empty, this method tries to migrate the
    /// database from the nRF Mesh 1.0.x to the new format. This
    /// is useful when the library or the Sample App has been updated.
    /// For fresh installs, when the storage is empty and the
    /// legacy version was not found this method returns `false`.
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
            proxyFilter = ProxyFilter(self)
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
            proxyFilter = ProxyFilter(self)
            return save()
        }
        return false
    }
    
    /// Saves the Mesh Network configuration in the storage.
    /// If storage is not given, a local file will be used.
    ///
    /// - returns: `True` if the network settings was saved, `false` otherwise.
    func save() -> Bool {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try! encoder.encode(meshData)
        return storage.save(data)
    }
    
}

// MARK: - Export / Import
    
public extension MeshNetworkManager {
    
    /// Returns the exported Mesh Network configuration as JSON Data.
    /// The returned Data can be transferred to another application and
    /// imported. The JSON is compatible with Bluetooth Mesh scheme.
    ///
    /// - returns: The mesh network configuration as JSON Data.
    func export() -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        return try! encoder.encode(meshData.meshNetwork)
    }
    
    /// Imports the Mesh Network configuration from the given Data.
    /// The data must contain valid JSON with Bluetooth Mesh scheme.
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
        networkManager = NetworkManager(self)
        proxyFilter = ProxyFilter(self)
        return meshNetwork
    }
    
}
