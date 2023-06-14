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

public extension Node {
    
    /// Returns whether the Node has knowledge about the given Application Key.
    /// The Application Key comparison bases only on the Key Index.
    ///
    /// - parameter applicationKey: The Application Key to look for.
    /// - returns: `True` if the Node has knowledge about the Application Key
    ///            with the same Key Index as given key, `false` otherwise.
    func knows(applicationKey: ApplicationKey) -> Bool {
        return knows(applicationKeyIndex: applicationKey.index)
    }
    
    /// Returns whether the Node has knowledge about Application Key with the
    /// given index.
    ///
    /// - parameter applicationKeyIndex: The Application Key Index to look for.
    /// - returns: `True` if the Node has knowledge about the Application Key
    ///            index, `false` otherwise.
    func knows(applicationKeyIndex: KeyIndex) -> Bool {
        return appKeys.contains { $0.index == applicationKeyIndex }
    }
    
    /// Returns whether the Node has knowledge about the given Network Key.
    /// The Network Key comparison bases only on the Key Index.
    ///
    /// - parameter networkKey: The Network Key to look for.
    /// - returns: `True` if the Node has knowledge about the Network Key
    ///            with the same Key Index as given key, `false` otherwise.
    func knows(networkKey: NetworkKey) -> Bool {
        return knows(networkKeyIndex: networkKey.index)
    }
    
    /// Returns whether the Node has knowledge about Network Key with the
    /// given index.
    ///
    /// - parameter networkKeyIndex: The Network Key Index to look for.
    /// - returns: `True` if the Node has knowledge about the Network Key
    ///            index, `false` otherwise.
    func knows(networkKeyIndex: KeyIndex) -> Bool {
        return netKeys.contains { $0.index == networkKeyIndex }
    }
    
    /// Returns whether any of the Element's Models are bound to the
    /// given Application Key.
    ///
    /// - parameter applicationKey: The Application Key to check bindings.
    /// - returns: `True` if there is at least one Model bound to the given
    ///            Application Key, `false` otherwise.
    func contains(modelBoundToApplicationKey applicationKey: ApplicationKey) -> Bool {
        return elements.contains { $0.hasModelBoundTo(applicationKey) }
    }
    
    /// Returns whether any of the Element's Models are bound to the
    /// given Application Key.
    ///
    /// - parameter applicationKey: The Application Key to check bindings.
    /// - returns: `True` if there is at least one Model bound to the given
    ///            Application Key, `false` otherwise.
    ///
    @available(*, deprecated, renamed: "contains(modelBoundToApplicationKey:)")
    func hasModelBoundTo(_ applicationKey: ApplicationKey) -> Bool {
        return elements.contains { $0.hasModelBoundTo(applicationKey) }
    }
    
    /// Returns whether the Node has at least one Application Key bound
    /// to the given Network Key.
    ///
    /// - parameter networkKey: The Network Key to check binding.
    /// - returns: `True` if at least one Application Key known to this Node
    ///            is bound to the given Network Key.
    func contains(applicationKeyBoundToNetworkKey networkKey: NetworkKey) -> Bool {
        return applicationKeys.contains(keyBoundTo: networkKey)
    }
    
    /// Returns whether the Node has at least one Application Key bound
    /// to the given Network Key.
    ///
    /// - parameter networkKey: The Network Key to check binding.
    /// - returns: `True` if at least one Application Key known to this Node
    ///            is bound to the given Network Key.
    @available(*, deprecated, renamed: "contains(applicationKeyBoundToNetworkKey:)")
    func hasApplicationKeyBoundTo(_ networkKey: NetworkKey) -> Bool {
        return applicationKeys.contains(keyBoundTo: networkKey)
    }
    
    /// Returns a list of Application Keys known to the Node, that are not
    /// bound to the given Model, and therefore can be bound to it.
    ///
    /// - parameter model: The Model which keys will be excluded.
    /// - returns: List of Application Keys that may be bound to the given Model.
    func applicationKeys(availableForModel model: Model) -> [ApplicationKey] {
        return applicationKeys.filter {
            !model.boundApplicationKeys.contains($0)
        }
    }
    
    /// Returns a list of Application Keys known to the Node, that are not
    /// bound to the given Model, and therefore can be bound to it.
    ///
    /// - parameter model: The Model which keys will be excluded.
    /// - returns: List of Application Keys that may be bound to the given Model.
    @available(*, deprecated, renamed: "applicationKeys(availableForModel:)")
    func applicationKeysAvailableFor(_ model: Model) -> [ApplicationKey] {
        return applicationKeys.filter {
            !model.boundApplicationKeys.contains($0)
        }
    }
    
}

public extension Array where Element == Node {
    
    /// Returns whether any of elements of this array is using the given
    /// Application Key.
    ///
    /// - parameter applicationKey: The Application Key to look for.
    /// - returns: `True` if any of the Nodes have knowledge about the
    ///            Application Key with the same Key Index as given key,
    ///            `false` otherwise.
    func knows(applicationKey: ApplicationKey) -> Bool {
        return knows(applicationKeyIndex: applicationKey.index)
    }
    
    /// Returns whether any of elements of this array is using an
    /// Application Key with given Key Index.
    ///
    /// - parameter applicationKeyIndex: The Application Key Index to look for.
    /// - returns: `True` if any of the Nodes have knowledge about the
    ///            Application Key Index, `false` otherwise.
    func knows(applicationKeyIndex: KeyIndex) -> Bool {
        return contains { $0.knows(applicationKeyIndex: applicationKeyIndex) }
    }
    
    /// Returns whether any of elements of this array is using the given
    /// Network Key.
    ///
    /// - parameter networkKey: The Network Key to look for.
    /// - returns: `True` if any of the Nodes have knowledge about the
    ///            Application Key with the same Key Index as given key,
    ///            `false` otherwise.
    func knows(networkKey: NetworkKey) -> Bool {
        return knows(networkKeyIndex: networkKey.index)
    }
    
    /// Returns whether any of elements of this array is using an
    /// Network Key with given Key Index.
    ///
    /// - parameter applicationKeyIndex: The Network Key Index to look for.
    /// - returns: `True` if any of the Nodes have knowledge about the
    ///            Network Key Index, `false` otherwise.
    func knows(networkKeyIndex: KeyIndex) -> Bool {
        return contains { $0.knows(networkKeyIndex: networkKeyIndex) }
    }
    
}
