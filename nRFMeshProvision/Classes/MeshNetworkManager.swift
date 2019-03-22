//
//  MeshNetworkManager.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 19/03/2019.
//

import Foundation

public class MeshNetworkManager {
    /// Mesh Network data.
    public private(set) var data: MeshData!
    /// Storage to keep the app data.
    private let storage: Storage
    
    // MARK: - Computed properties
    
    /// Convinient getter to get MeshNetwork object.
    public var meshNetwork: MeshNetwork? {
        return data.meshNetwork
    }
    
    /// Returns true if Mesh Network has been created.
    public var isNetworkCreated: Bool {
        return data.meshNetwork != nil
    }
    
    // MARK: - Constructors
    
    /// Initializes the MeshNetworkManager.
    /// If storage not provided, a local file will be used instead.
    ///
    /// - parameter storage: The storage to use to save the network configuration.
    /// - seeAlso: `LocalStorage`
    public init(using storage: Storage = LocalStorage()) {
        self.storage = storage
        self.data = MeshData()
    }
    
    /// Initializes the MeshNetworkManager. It will use the `LocalStorage`
    /// with the given file name.
    ///
    /// - parameter fileName: File name to keep the configuration.
    /// - seeAlso: `LocalStorage`
    public convenience init(using fileName: String) {
        self.init(using: LocalStorage(fileName: fileName))
    }
    
    // MARK: - Mesh Network API
    
    /// Generates a new Mesh Network configuration with random or default values.
    /// This will override the existing one, if such exists.
    ///
    /// - parameter name: The user given network name.
    public func createNewMeshNetwork(named name: String) -> MeshNetwork {
        let network = MeshNetwork(name: name)
        data.meshNetwork = network
        return network
    }
    
    // MARK: - Save / Load
    
    /// Loads the Mesh Network configuration from the storage.
    /// If storage is not given, a local file will be used.
    ///
    /// - returns: True if the network settings were loaded, false otherwise.
    /// - throws: If loading configuration failed.
    public func load() throws -> Bool {
        if let data = storage.load() {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            self.data = try decoder.decode(MeshData.self, from: data)
            return true
        }
        return false
    }
    
    /// Saves the Mesh Network configuration in the storage.
    /// If storage is not given, a local file will be used.
    ///
    /// - returns: True if the network settings was saved, false otherwise.
    public func save() -> Bool {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try! encoder.encode(self.data)
        return storage.save(data)
    }
    
    // MARK: - Export / Import
    
    /// Returns the exported Mesh Network configuration as JSON Data.
    /// The returned Data can be transferred to another application and
    /// imported. The JSON is compatible with Bluetooth Mesh scheme.
    public func export() -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        return try! encoder.encode(data.meshNetwork)
    }
    
    /// Imports the Mesh Network configuration from the given Data.
    /// The data must contain valid JSON with Bluetooth Mesh scheme.
    ///
    /// - parameter data: JSON as Data.
    public func `import`(from data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let meshNetwork = try decoder.decode(MeshNetwork.self, from: data)
        self.data.meshNetwork = meshNetwork
    }
}
