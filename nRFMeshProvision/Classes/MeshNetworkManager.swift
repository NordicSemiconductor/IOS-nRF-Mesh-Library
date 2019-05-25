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
    func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, from source: MeshAddress)
}

public class MeshNetworkManager {
    /// Mesh Network data.
    private var meshData: MeshData!
    /// Storage to keep the app data.
    private let storage: Storage
    
    public weak var delegate: MeshNetworkDelegate?
    
    // MARK: - Computed properties
    
    /// Returns the MeshNetwork object.
    public var meshNetwork: MeshNetwork? {
        return meshData.meshNetwork
    }
    
    /// Returns true if Mesh Network has been created.
    public var isNetworkCreated: Bool {
        return meshData.meshNetwork != nil
    }
    
    // MARK: - Constructors
    
    /// Initializes the MeshNetworkManager.
    /// If storage not provided, a local file will be used instead.
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
    
    /// Generates a new Mesh Network configuration with random or default values.
    /// This will override the existing one, if such exists.
    /// The mesh network will contain one Provisioner with given name.
    ///
    /// Network Keys and Application Keys must be added manually
    /// using `add(networkKey:name)` and `add(applicationKey:name)`.
    ///
    /// - parameter name:            The user given network name.
    /// - parameter provisionerName: The user given local provisioner name.
    func createNewMeshNetwork(withName name: String, by provisionerName: String) -> MeshNetwork {
        let network = MeshNetwork(name: name)
        
        // Add a new default provisioner.
        try! network.add(provisioner: Provisioner(name: provisionerName))
        
        meshData.meshNetwork = network
        return network
    }
    
    /// Generates a new Mesh Network configuration with random or default values.
    /// This will override the existing one, if such exists.
    /// The mesh network will contain the given Provisioner.
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
        return network
    }
    
}

// MARK: - Send / Receive Mesh Messages

public extension MeshNetworkManager {
    
    func bearerDidDeliverData(_ data: Data, ofType type: MessageType) {
        // TODO
    }
    
    func createMeshMessage(_ message: MeshMessage, for destination: MeshAddress, withMtu mtu: Int) -> [Data] {
        // TODO
        return []
    }
    
    func createMeshMessage(_ message: MeshMessage, for destination: Address, withMtu mtu: Int) throws -> [Data] {
        guard let address = MeshAddress(destination) else {
            throw MeshMessageError.invalidAddress
        }
        return createMeshMessage(message, for: address, withMtu: mtu)
    }
    
}

// MARK: - Helper methods for Bearer support

extension MeshNetworkManager: BearerDataDelegate {
    
    public func bearer(_ bearer: Bearer, didDeliverData data: Data, ofType type: MessageType) {
        bearerDidDeliverData(data, ofType: type)
    }
    
    func createMeshMessage(_ message: MeshMessage, for destination: MeshAddress, andSendUsing bearer: Bearer) throws {
        let packets = createMeshMessage(message, for: destination, withMtu: bearer.mtu)
        try packets.forEach {
            try bearer.send($0, ofType: .networkPdu)
        }
    }
    
    func createMeshMessage(_ message: MeshMessage, for destination: Address, andSendUsing bearer: Bearer) throws {
        guard let address = MeshAddress(destination) else {
            throw MeshMessageError.invalidAddress
        }
        try createMeshMessage(message, for: address, andSendUsing: bearer)
    }
    
}

// MARK: - Save / Load

public extension MeshNetworkManager {
    
    /// Loads the Mesh Network configuration from the storage.
    /// If storage is not given, a local file will be used.
    ///
    /// - returns: True if the network settings were loaded, false otherwise.
    /// - throws: If loading configuration failed.
    func load() throws -> Bool {
        if let data = storage.load() {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            meshData = try decoder.decode(MeshData.self, from: data)
            meshNetwork!.provisioners.forEach {
                $0.meshNetwork = meshNetwork
            }
            return true
        }
        return false
    }
    
    /// Saves the Mesh Network configuration in the storage.
    /// If storage is not given, a local file will be used.
    ///
    /// - returns: True if the network settings was saved, false otherwise.
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
    func export() -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        return try! encoder.encode(meshData.meshNetwork)
    }
    
    /// Imports the Mesh Network configuration from the given Data.
    /// The data must contain valid JSON with Bluetooth Mesh scheme.
    ///
    /// - parameter data: JSON as Data.
    /// - throws: An error if import or adding local Provisioner failed.
    func `import`(from data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let meshNetwork = try decoder.decode(MeshNetwork.self, from: data)
        meshNetwork.provisioners.forEach {
            $0.meshNetwork = meshNetwork
        }
        
        self.meshData.meshNetwork = meshNetwork
    }
    
}
