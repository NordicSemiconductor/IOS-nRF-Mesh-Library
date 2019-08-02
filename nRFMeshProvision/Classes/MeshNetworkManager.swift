//
//  MeshNetworkManager.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 19/03/2019.
//

import Foundation

public protocol MeshNetworkDelegate: class {
    
    /// A callback called whenever a Mesh Message has been received
    /// from the mesh network.
    ///
    /// - parameters:
    ///   - meshNetwork: The mesh network from which the message has
    ///                  been received.
    ///   - message:     The received message.
    ///   - source:      The Unicast Address of the Element from which
    ///                  the message was sent.
    func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, from source: Address)
    
    /// A callback called when an unsegmented message was sent to the
    /// `transmitter`, or when all segments of a segmented message targetting
    /// a Unicast Address were acknowledged by the target Node.
    ///
    /// - parameters:
    ///   - meshNetwork: The mesh network to which the message has
    ///                  been sent.
    ///   - message:     The message that has been sent.
    ///   - source:      The Unicast Address of the Element to which
    ///                  the message was sent.
    func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, to destination: Address)
    
    /// A callback called when a message failed to be sent to the target
    /// Node. For unsegmented messages this may happen when the `transmitter`
    /// was `nil`, or has thrown an exception from `send(data:ofType)`.
    /// For segmented messages targetting a Unicast Address this may also be
    /// called when sending timeouted before all of the segments were
    /// acknowledged by the target Node, or when the target Node is busy and
    /// not able to proceed the message at the moment.
    ///
    /// Possible errors are:
    /// - Any error thrown by the `transmitter`.
    /// - `BearerError.bearerClosed` - when the `transmitter` object was net set.
    /// - `LowerTransportError.busy` - when the target Node is busy and can't
    ///   accept the message.
    /// - `LowerTransportError.timeout` - when the segmented message targetting
    ///   a Unicast Address was not acknowledgned before the `retransmissionLimit`
    ///   was reached.
    ///
    /// - parameters:
    ///   - meshNetwork: The mesh network to which the message has
    ///                  been sent.
    ///   - message:     The message that has failed to be delivered.
    ///   - destination: The Unicast Address of the Element to which
    ///                  the message was sent.
    ///   - error:       The error that occurred.
    func meshNetwork(_ meshNetwork: MeshNetwork, failedToDeliverMessage message: MeshMessage, to destination: Address, error: Error)
    
}

public extension MeshNetworkDelegate {
    
    func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, to destination: Address) {
        // Empty.
    }
    
    func meshNetwork(_ meshNetwork: MeshNetwork, failedToDeliverMessage message: MeshMessage, to destination: Address, error: Error) {
        // Empty.
    }
    
}

public class MeshNetworkManager {
    /// Mesh Network data.
    private var meshData: MeshData
    /// The Network Layer handler.
    private var networkManager: NetworkManager?
    /// Storage to keep the app data.
    private let storage: Storage
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
    /// of the Provisioner's Node.
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
    /// Number of times a non-acknowledged segment will be re-send before
    /// the message will be cancelled.
    ///
    /// The limit may be decreased with increasing of `transmissionTimerInterval`
    /// as the target Node has more time to reply with the Segment
    /// Acknowledgment message.
    public var retransmissionLimit: Int = 10
    
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
    /// If storage is not provided, a local file will be used instead.
    ///
    /// - parameter storage: The storage to use to save the network configuration.
    /// - seeAlso: `LocalStorage`
    public init(using storage: Storage = LocalStorage()) {
        self.storage = storage
        self.meshData = MeshData()
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
    /// - parameter name:            The user given network name.
    /// - parameter provisionerName: The user given local provisioner name.
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
    /// - parameter name:      The user given network name.
    /// - parameter provisioner: The default Provisioner.
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
    /// - parameter data: The PDU received.
    /// - parameter type: The PDU type.
    func bearerDidDeliverData(_ data: Data, ofType type: PduType) {
        guard let networkManager = networkManager else {
            return
        }
        networkManager.handle(incomingPdu: data, ofType: type)
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
    /// If the `transporter` throws an error during sending, this error will be ignored.
    ///
    /// - parameter message:        The message to be sent.
    /// - parameter destination:    The destination address.
    /// - parameter applicationKey: The Application Key to sign the message.
    func send(_ message: MeshMessage, to destination: Address, using applicationKey: ApplicationKey) {
        guard let networkManager = networkManager else {
            return
        }
        networkManager.send(message, to: destination, using: applicationKey)
    }
    
    /// Does the same as the other `send(:to:key)`, but takes
    /// MeshAddress as destination address, which could be used for virtual
    /// labels.
    ///
    /// - parameter message:        The message to be sent.
    /// - parameter destination:    The destination address.
    /// - parameter applicationKey: The Application Key to sign the message.
    func send(_ message: MeshMessage, to destination: MeshAddress, using applicationKey: ApplicationKey) {
        send(message, to: destination.address, using: applicationKey)
    }
    
    /// Encrypts the message with the first Application Key bound to the given
    /// Model and a Network Key bound to it, and sends it to the Node
    /// to which the Model belongs to.
    ///
    /// If the `transporter` throws an error during sending, this error will be ignored.
    ///
    /// - parameter message: The message to be sent.
    /// - parameter model:   The destination Model.
    func send(_ message: MeshMessage, to model: Model) {
        guard let element = model.parentElement else {
            print("Error: Element does not belong to a Node")
            return
        }
        guard let firstKeyIndex = model.bind.first,
              let meshNetwork = meshNetwork,
              let applicationKey = meshNetwork.applicationKeys[firstKeyIndex] else {
            print("Error: Model is not bound to any Application Key")
            return
        }
        send(message, to: element.unicastAddress, using: applicationKey)
    }
    
    // TODO: Add send to Group method.
    
    /// Sends Configuration Message to the Node with given destination Address.
    /// The `destination` must be a Unicast Address, otherwise the method
    /// does nothing.
    ///
    /// If the `transporter` throws an error during sending, this error will be ignored.
    ///
    /// - parameter message:     The message to be sent.
    /// - parameter destination: The destination Unicast Address.
    func send(_ message: ConfigMessage, to destination: Address) {
        guard let networkManager = networkManager else {
            return
        }
        networkManager.send(message, to: destination)
    }
    
    /// Sends Configuration Message to the given Node.
    ///
    /// If the `transporter` throws an error during sending, this error will be ignored.
    ///
    /// - parameter message: The message to be sent.
    /// - parameter node:    The destination Node.
    func send(_ message: ConfigMessage, to node: Node) {
        send(message, to: node.unicastAddress)
    }
    
    /// Sends Configuration Message to the given Node.
    ///
    /// If the `transporter` throws an error during sending, this error will be ignored.
    ///
    /// - parameter message: The message to be sent.
    /// - parameter element: The destination Element.
    func send(_ message: ConfigMessage, to element: Element) {
        guard let node = element.parentNode else {
            print("Error: Element does not belong to a Node")
            return
        }
        send(message, to: node)
    }
    
    /// Sends Configuration Message to the given Node.
    ///
    /// If the `transporter` throws an error during sending, this error will be ignored.
    ///
    /// - parameter message: The message to be sent.
    /// - parameter model:   The destination Model.
    func send(_ message: ConfigMessage, to model: Model) {
        guard let element = model.parentElement else {
            print("Error: Model does not belong to an Element")
            return
        }
        send(message, to: element)
    }
    
}

// MARK: - Helper methods for Bearer support

extension MeshNetworkManager: BearerDataDelegate {
    
    public func bearer(_ bearer: Bearer, didDeliverData data: Data, ofType type: PduType) {
        bearerDidDeliverData(data, ofType: type)
    }
    
}

// MARK: - Save / Load

public extension MeshNetworkManager {
    
    /// Loads the Mesh Network configuration from the storage.
    /// If storage is not given, a local file will be used.
    ///
    /// - returns: `True` if the network settings were loaded, `false` otherwise.
    /// - throws: If loading configuration failed.
    func load() throws -> Bool {
        if let data = storage.load() {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            meshData = try decoder.decode(MeshData.self, from: data)
            guard let network = meshData.meshNetwork else {
                return false
            }
            network.provisioners.forEach {
                $0.meshNetwork = network
            }
            networkManager = NetworkManager(self)
            return true
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
    /// - throws: This method throws an error if import or adding
    ///           the local Provisioner failed.
    func `import`(from data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let meshNetwork = try decoder.decode(MeshNetwork.self, from: data)
        meshNetwork.provisioners.forEach {
            $0.meshNetwork = meshNetwork
        }
        
        meshData.meshNetwork = meshNetwork
        networkManager = NetworkManager(self)
    }
    
}
