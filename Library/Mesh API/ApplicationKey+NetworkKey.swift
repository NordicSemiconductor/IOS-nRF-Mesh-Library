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

public extension ApplicationKey {
    
    /// Bounds the Application Key to the given Network Key.
    /// The Application Key must not be in use. If any of the network Nodes
    /// already knows this key, this method throws an error.
    ///
    /// - parameter networkKey: The Network Key to bound the Application Key to.
    func bind(to networkKey: NetworkKey) throws {
        guard let meshNetwork = meshNetwork else {
            return
        }
        guard !isUsed(in: meshNetwork) else {
            throw MeshNetworkError.keyInUse
        }
        boundNetworkKeyIndex = networkKey.index
    }
    
    /// Returns whether the Application Key is bound to the given
    /// Network Key. The Key comparison bases on Key Index property.
    ///
    /// - parameter networkKey: The Network Key to check.
    /// - returns: `True`, if the Application Key is bound to the
    ///            given Network Key.
    func isBound(to networkKey: NetworkKey) -> Bool {
        return boundNetworkKeyIndex == networkKey.index
    }
    
    /// Returns whether the Application Key is bound to any of the
    /// given Network Keys. The Key comparison bases on Key Index property.
    ///
    /// - parameter networkKeys: The Network Keys to check.
    /// - returns: `True`, if the Application Key is bound to any of
    ///            the given Network Keys.
    func isBound(toAnyOf networkKeys: [NetworkKey]) -> Bool {
        return networkKeys.contains { isBound(to: $0) }
    }

    /// The Network Key bound to this Application Key.
    var boundNetworkKey: NetworkKey {
        return meshNetwork!.networkKeys[boundNetworkKeyIndex]!
    }
}

// MARK: - Array methods

public extension Array where Element == ApplicationKey {
    
    /// Returns whether any of the Application Keys in the array is bound to
    /// the given Network Key. The Key comparison bases on Key Index property.
    ///
    /// - parameter networkKey: The Network Key to check.
    /// - returns: `True`, if the array contains an Application Key bound to
    ///            the given Network Key, `false` otherwise.
    func contains(keyBoundTo networkKey: NetworkKey) -> Bool {
        return contains { $0.isBound(to: networkKey) }
    }
    
    /// Filters the list to contain only those Application Keys, that are
    /// bound to the given Network Key.
    ///
    /// - parameter networkKey: The Network Key of interest.
    /// - returns: Filtered list of Application Keys.
    func boundTo(_ networkKey: NetworkKey) -> [ApplicationKey] {
        return filter { $0.isBound(to: networkKey) }
    }
    
    /// Filters the list to contain only those Application Keys, that are
    /// bound to the given Network Keys.
    ///
    /// - parameter networkKeys: The Network Keys of interest.
    /// - returns: Filtered list of Application Keys.
    func boundTo(_ networkKeys: [NetworkKey]) -> [ApplicationKey] {
        return filter { $0.isBound(toAnyOf: networkKeys) }
    }
    
}

