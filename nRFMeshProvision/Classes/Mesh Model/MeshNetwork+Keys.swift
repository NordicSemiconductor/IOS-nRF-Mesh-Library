//
//  MeshNetwork+Keys.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 25/04/2019.
//

import Foundation

public extension MeshNetwork {
    
    /// Returns the next available Key Index that can be assigned
    /// to a new Application Key.
    var nextAvailableApplicationKeyIndex: KeyIndex {
        return (applicationKeys.last?.index ?? -1) + 1 as KeyIndex
    }
    
    /// Returns the next available Key Index that can be assigned
    /// to a new Network Key.
    var nextAvailableNetworkKeyIndex: KeyIndex {
        return (networkKeys.last?.index ?? -1) + 1 as KeyIndex
    }
    
    /// Adds a new Application Key and binds it to the first Network Key.
    ///
    /// - parameter applicationKey: The 128-bit Application Key.
    /// - parameter name:           The human readable name.
    /// - throws: This method throws an error if the key is not 128-bit long,
    ///           there isn't any Network Key to bind the new key to
    ///           or the assigned Key Index is out of range.
    /// - seeAlso: `nextAvailableApplicationKeyIndex`
    func add(applicationKey: Data, name: String) throws -> ApplicationKey {
        guard applicationKey.count == 16 else {
            throw MeshModelError.invalidKey
        }
        guard let defaultNetworkKey = networkKeys.first else {
            throw MeshModelError.noNetworkKey
        }
        let key = try ApplicationKey(name: name, index: nextAvailableApplicationKeyIndex,
                                 key: applicationKey, bindTo: defaultNetworkKey)
        applicationKeys.append(key)
        
        // Make the local Provisioner aware of the new key.
        if let localProvisioner = provisioners.first,
           let n = node(for: localProvisioner) {
            n.appKeys.append(Node.NodeKey(of: key))
        }
        return key
    }
    
    /// Removes Applicaiton Key with given Key Index.
    ///
    /// - parameter index: The Key Index of a key to be removed.
    /// - returns: The removed key.
    /// - throws: The method throws if the key is in use and cannot be
    ///           removed, or such Key Index was not found.
    func remove(applicationKeyWithKeyIndex index: KeyIndex) throws -> ApplicationKey {
        let i = applicationKeys.firstIndex(where: { $0.index == index }) ?? -1
        return try remove(applicationKeyAt: i)
    }
    
    /// Removes Applicaiton Key at the given index.
    ///
    /// - parameter index: The position of the element to remove.
    ///                    `index` must be a valid index of the array.
    /// - returns: The removed key.
    /// - throws: The method throws if the key is in use and cannot be
    ///           removed.
    func remove(applicationKeyAt index: Int) throws -> ApplicationKey {
        let applicationKey = applicationKeys[index]
        // Ensure no node is using this Application Key.
        guard !applicationKey.isUsed(in: self) else {
            throw MeshModelError.keyInUse
        }
        return applicationKeys.remove(at: index)
    }
    
    /// Removes the given Application Key. This method does nothing if the
    /// Application Key was not added to the Mesh Network before.
    ///
    /// - parameter applicationKey: Key to be removed.
    /// - throws: The method throws if the key is in use and cannot be
    ///           removed.
    func remove(applicationKey: ApplicationKey) throws {
        if let index = applicationKeys.firstIndex(of: applicationKey) {
            _ = try remove(applicationKeyAt: index)
        }
    }
    
    /// Adds a new Network Key.
    ///
    /// - parameter networkKey: The 128-bit Application Key.
    /// - parameter name:       The human readable name.
    /// - throws: This method throws an error if the key is not 128-bit long
    ///           or the assigned Key Index is out of range.
    /// - seeAlso: `nextAvailableNetworkKeyIndex`
    func add(networkKey: Data, name: String) throws -> NetworkKey {
        guard networkKey.count == 16 else {
            throw MeshModelError.invalidKey
        }
        let key = try NetworkKey(name: name, index: nextAvailableNetworkKeyIndex, key: networkKey)
        networkKeys.append(key)
        
        // Make the local Provisioner aware of the new key.
        if let localProvisioner = provisioners.first,
           let n = node(for: localProvisioner) {
            n.netKeys.append(Node.NodeKey(of: key))
        }
        return key
    }
    
    /// Removes Network Key with given Key Index.
    ///
    /// - parameter index: The Key Index of a key to be removed.
    /// - returns: The removed key.
    /// - throws: The method throws if the key is in use and cannot be
    ///           removed, or such Key Index was not found.
    func remove(networkKeyWithKeyIndex index: KeyIndex) throws -> NetworkKey {
        let i = networkKeys.firstIndex(where: { $0.index == index }) ?? -1
        return try remove(networkKeyAt: i)
    }
    
    /// Removes Network Key at the given index.
    ///
    /// - parameter index: The position of the element to remove.
    ///                    `index` must be a valid index of the array.
    /// - returns: The removed key.
    /// - throws: The method throws if the key is in use and cannot be
    ///           removed.
    func remove(networkKeyAt index: Int) throws -> NetworkKey {
        let networkKey = networkKeys[index]
        // Ensure no node is using this Application Key.
        guard !networkKey.isUsed(in: self) else {
            throw MeshModelError.keyInUse
        }
        return networkKeys.remove(at: index)
    }
    
    /// Removes the given Network Key. This method does nothing if the
    /// Network Key was not added to the Mesh Network before.
    ///
    /// - parameter networkKey: Key to be removed.
    /// - throws: The method throws if the key is in use and cannot be
    ///           removed.
    func remove(networkKey: NetworkKey) throws {
        if let index = networkKeys.firstIndex(of: networkKey) {
            _ = try remove(networkKeyAt: index)
        }
    }
    
}
