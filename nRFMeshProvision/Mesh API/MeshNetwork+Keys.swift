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

public extension MeshNetwork {
    
    /// Next available Key Index that can be assigned to a new Application Key.
    ///
    /// - note: This method does not look for gaps in key indexes. It returns the
    ///         next available Key Index after the last Key Index used.
    var nextAvailableApplicationKeyIndex: KeyIndex? {
        if applicationKeys.isEmpty {
            return 0
        }
        guard let lastAppKey = applicationKeys.last, (lastAppKey.index + 1).isValidKeyIndex else {
            return nil
        }
        return lastAppKey.index + 1
    }
    
    /// Next available Key Index that can be assigned to a new Network Key.
    ///
    /// - note: This method does not look for gaps in key indexes. It returns the
    ///         next available Key Index after the last Key Index used.
    var nextAvailableNetworkKeyIndex: KeyIndex? {
        if networkKeys.isEmpty {
            return 0
        }
        guard let lastNetKey = networkKeys.last, (lastNetKey.index + 1).isValidKeyIndex else {
            return nil
        }
        return lastNetKey.index + 1
    }
    
    /// Adds a new Application Key and binds it to the first Network Key.
    ///
    /// - parameter applicationKey: The 128-bit Application Key.
    /// - parameter index:          An optional Key Index to assign. If `nil`,
    ///                             the next available Key Index will be assigned
    ///                             automatically.
    /// - parameter name:           The human readable name.
    /// - throws: This method throws an error if the key is not 128-bit long,
    ///           there isn't any Network Key to bind the new key to
    ///           or the assigned Key Index is out of range.
    @discardableResult
    func add(applicationKey: Data, withIndex index: KeyIndex? = nil, name: String) throws -> ApplicationKey {
        guard let defaultNetworkKey = networkKeys.first else {
            throw MeshNetworkError.noNetworkKey
        }
        guard let nextIndex = index ?? nextAvailableApplicationKeyIndex else {
            throw MeshNetworkError.keyIndexOutOfRange
        }
        let key = try ApplicationKey(name: name, index: nextIndex,
                                     key: applicationKey, boundTo: defaultNetworkKey)
        add(applicationKey: key)
        return key
    }
    
    /// Removes Application Key with given Key Index.
    ///
    /// - parameter index: The Key Index of a key to be removed.
    /// - parameter force: If set to `true`, the key will be deleted even
    ///                    if there are other Nodes known to use this key.
    /// - returns: The removed key.
    /// - throws: The method throws if the key is in use and cannot be
    ///           removed (unless `force` was set to `true`).
    func remove(applicationKeyWithKeyIndex index: KeyIndex, force: Bool = false) throws {
        if let index = applicationKeys.firstIndex(where: { $0.index == index }) {
            _ = try remove(applicationKeyAt: index, force: force)
        }
    }
    
    /// Removes Application Key at the given index.
    ///
    /// - parameter index: The position of the element to remove.
    ///                    `index` must be a valid index of the array.
    /// - parameter force: If set to `true`, the key will be deleted even
    ///                    if there are other Nodes known to use this key.
    /// - returns: The removed key.
    /// - throws: The method throws if the key is in use and cannot be
    ///           removed (unless `force` was set to `true`).
    func remove(applicationKeyAt index: Int, force: Bool = false) throws -> ApplicationKey {
        let applicationKey = applicationKeys[index]
        // Ensure no Node is using this Application Key.
        guard force || !applicationKey.isUsed(in: self) else {
            throw MeshNetworkError.keyInUse
        }
        applicationKey.meshNetwork = nil
        timestamp = Date()
        return applicationKeys.remove(at: index)
    }
    
    /// Removes the given Application Key. This method does nothing if the
    /// Application Key was not added to the Mesh Network before.
    ///
    /// - parameter applicationKey: Key to be removed.
    /// - parameter force: If set to `true`, the key will be deleted even
    ///                    if there are other Nodes known to use this key.
    /// - throws: The method throws if the key is in use and cannot be
    ///           removed (unless `force` was set to `true`).
    func remove(applicationKey: ApplicationKey, force: Bool = false) throws {
        if let index = applicationKeys.firstIndex(of: applicationKey) {
            _ = try remove(applicationKeyAt: index, force: force)
        }
    }
    
    /// Adds a new Network Key.
    ///
    /// - parameter networkKey: The 128-bit Application Key.
    /// - parameter index:      The optional Key Index to assign. If `nil`, the next
    ///                         available Key Index will be assigned automatically.
    /// - parameter name:       The human readable name.
    /// - throws: This method throws an error if the key is not 128-bit long
    ///           or the assigned Key Index is out of range.
    /// - seeAlso: ``MeshNetwork/nextAvailableNetworkKeyIndex``
    @discardableResult
    func add(networkKey: Data, withIndex index: KeyIndex? = nil, name: String) throws -> NetworkKey {
        guard let nextIndex = index ?? nextAvailableNetworkKeyIndex else {
            throw MeshNetworkError.keyIndexOutOfRange
        }
        let key = try NetworkKey(name: name, index: nextIndex, key: networkKey)
        add(networkKey: key)
        return key
    }
    
    /// Removes Network Key with given Key Index.
    ///
    /// - parameter index: The Key Index of a key to be removed.
    /// - parameter force: If set to `true`, the key will be deleted even
    ///                    if there are other Nodes known to use this key.
    /// - returns: The removed key.
    /// - throws: The method throws if the key is in use and cannot be
    ///           removed (unless `force` was set to `true`).
    func remove(networkKeyWithKeyIndex index: KeyIndex, force: Bool = false) throws {
        if let networkKey = networkKeys[index] {
            _ = try remove(networkKey: networkKey, force: force)
        }
    }
    
    /// Removes Network Key at the given index.
    ///
    /// - parameter index: The position of the element to remove.
    ///                    `index` must be a valid index of the array.
    /// - parameter force: If set to `true`, the key will be deleted even
    ///                    if there are other Nodes known to use this key.
    /// - returns: The removed key.
    /// - throws: The method throws if the key is in use and cannot be
    ///           removed (unless `force` was set to `true`).
    func remove(networkKeyAt index: Int, force: Bool = false) throws -> NetworkKey {
        let networkKey = networkKeys[index]
        // Ensure no Node is using this Application Key.
        guard force || !networkKey.isPrimary && !networkKey.isUsed(in: self) else {
            throw MeshNetworkError.keyInUse
        }
        timestamp = Date()
        return networkKeys.remove(at: index)
    }
    
    /// Removes the given Network Key. This method does nothing if the
    /// Network Key was not added to the Mesh Network before.
    ///
    /// - parameter networkKey: Key to be removed.
    /// - parameter force: If set to `true`, the key will be deleted even
    ///                    if there are other Nodes known to use this key.
    /// - throws: The method throws if the key is in use and cannot be
    ///           removed (unless `force` was set to `true`).
    func remove(networkKey: NetworkKey, force: Bool = false) throws {
        if let index = networkKeys.firstIndex(of: networkKey) {
            _ = try remove(networkKeyAt: index, force: force)
        }
    }
    
}
