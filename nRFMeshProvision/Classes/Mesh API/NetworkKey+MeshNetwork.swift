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

public extension NetworkKey {
    
    /// Returns whether the Network Key is the Primary Network Key.
    /// The Primary key is the one which Key Index is equal to 0.
    ///
    /// A Primary Network Key may not be removed from the mesh network,
    /// but can be removed from any Node using Config Net Key Delete
    /// messages encrypted using an Application Key bound to a different
    /// Network Key.
    var isPrimary: Bool {
        return index == 0
    }
    
    /// Returns whether the Network Key is a secondary Network Key,
    /// that is the Key Index is NOT equal to 0.
    var isSecondary: Bool {
        return !isPrimary
    }
    
    /// Return whether the Network Key is used in the given mesh network.
    ///
    /// A `true` is returned when the Network Key is added to Network Keys
    /// array of the network and is known to at least one node, or bound
    /// to an existing Application Key.
    ///
    /// An used Network Key may not be removed from the network.
    ///
    /// - parameter meshNetwork: The mesh network to look the key in.
    /// - returns: `True` if the key is used in the given network,
    ///            `false` otherwise.
    func isUsed(in meshNetwork: MeshNetwork) -> Bool {
        let localProvisioner = meshNetwork.localProvisioner
        return meshNetwork.networkKeys.contains(self) &&
            (
                // Network Key known by at least one node (except the local Provisioner).
                meshNetwork.nodes
                    .filter { $0.uuid != localProvisioner?.uuid }
                    .knows(networkKey: self) ||
                // Network Key bound to an Application Key.
                meshNetwork.applicationKeys.contains(keyBoundTo: self)
            )
    }
    
}
