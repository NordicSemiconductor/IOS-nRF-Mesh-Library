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

public extension Array where Element == NetworkKey {
    
    subscript(networkId: Data) -> NetworkKey? {
        return first { $0.networkId == networkId }
    }
    
    subscript(keyIndex: KeyIndex) -> NetworkKey? {
        return first { $0.index == keyIndex }
    }
    
    /// The primary Network Key, that is the one with key index 0.
    /// If the primary Network Key is not known, it's set to `nil`.
    var primaryKey: NetworkKey? {
        return first { $0.isPrimary }
    }
    
    /// Returns a new list of Network Keys containing all the Network Keys
    /// of this list known to the given Node.
    ///
    /// - parameter node: The Node used to filter Network Keys.
    /// - returns: A new list containing all the Network Keys of this list
    ///            known to the given node.
    func knownTo(node: Node) -> [NetworkKey] {
        return filter { node.knows(networkKey: $0) }
    }
    
    /// Returns a new list of Network Keys containing all the Network Keys
    /// of this list NOT known to the given Node.
    ///
    /// - parameter node: The Node used to filter Network Keys.
    /// - returns: A new list containing all the Network Keys of this list
    ///            NOT known to the given node.
    func notKnownTo(node: Node) -> [NetworkKey] {
        return filter { !node.knows(networkKey: $0) }
    }
    
}
