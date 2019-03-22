//
//  Storage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 20/03/2019.
//

import Foundation

/// A protocol used to save and restore the Mesh Network configuration.
/// The configuration saved in the storage should not be shared to another
/// device, as it contains some local configuration. Instead, use `export()`
/// method to get the JSON complient with Bluetooth Mesh scheme.
public protocol Storage {
    /// Loads data from the storage.
    ///
    /// - returns: Data or nil if not found.
    func load() -> Data?
    
    /// Save given data.
    ///
    /// - returns: True in case of success, false otherwise.
    func save(_ data: Data) -> Bool
}

/// A Storage implementation which will save the data in a local file
/// with given name. The file is stored in app's document directory in
/// user domain.
open class LocalStorage: Storage {
    private let path: String
    
    public init(fileName: String = "MeshNetwork.json") {
        self.path = fileName
    }
    
    public func load() -> Data? {
        // Load JSON form local file
        if let fileURL = getStorageFile() {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    return try Data(contentsOf: fileURL)
                } catch {
                    print(error)
                }
            }
        }
        return nil
    }
    
    public func save(_ data: Data) -> Bool {
        if let fileURL = getStorageFile() {
            do {
                try data.write(to: fileURL)
                return true
            } catch {
                print(error)
            }
        }
        return false
    }
    
    /// Returns the local file in which the Mesh configuration is stored.
    open func getStorageFile() -> URL? {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return url?.appendingPathComponent(path)
    }
}
