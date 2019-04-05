//
//  MeshNetworkManager.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 19/03/2019.
//

import Foundation

public class MeshNetworkManager {
    /// Mesh Network data.
    private var meshData: MeshData!
    /// Storage to keep the app data.
    private let storage: Storage
    
    // MARK: - Computed properties
    
    /// Returns the Global TTL property.
    public var globalTTL: UInt8 {
        set {
            meshData.globalTTL = newValue
        }
        get {
            return meshData.globalTTL
        }
    }
    
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
    /// The mesh network will contain one provisioner with given name.
    ///
    /// - parameter name:          The user given network name.
    /// - parameter provionerName: The user given local provisioner name.
    func createNewMeshNetwork(named name: String, by provionerName: String) -> MeshNetwork {
        let network = MeshNetwork(name: name)
        
        // Add a new default provisioner.
        try! network.add(provisioner: Provisioner(name: provionerName))
        
        meshData.meshNetwork = network
        return network
    }
    
    /// Generates a new Mesh Network configuration with random or default values.
    /// This will override the existing one, if such exists.
    /// The mesh network will contain the given Provisioner.
    ///
    /// - parameter name:      The user given network name.
    /// - parameter provioner: The default Provisioner.
    func createNewMeshNetwork(named name: String, by provioner: Provisioner) -> MeshNetwork {
        let network = MeshNetwork(name: name)
        
        // Add a new default provisioner.
        try! network.add(provisioner: provioner)
        
        meshData.meshNetwork = network
        return network
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
        
        self.meshData.meshNetwork = meshNetwork
    }
    
    /// Sets the given Provisioner as the one that will be used for
    /// provisioning new nodes, sending commands, etc. It will be moved
    /// to index 0 in the list of provisioners in the mesh network.
    ///
    /// The Provisioner will be added to the mesh network if it's not
    /// there already. Adding the Provisioner may throw an error,
    /// for example when the ranges overlap with ranges of another
    /// Provisioner or there are no free unicast addresses to be assigned.
    ///
    /// - parameter provisioner: The Provisioner to be used for provisioning.
    /// - throws: An error if adding the Provisioner failed.
    func setLocalProvisioner(_ provisioner: Provisioner) throws {
        if let meshNetwork = meshData.meshNetwork {
            
            if !meshNetwork.hasProvisioner(with: provisioner.uuid) {
                try meshNetwork.add(provisioner: provisioner)
            }
            
            meshNetwork.setMainProvisioner(provisioner)
        }
    }
    
}
