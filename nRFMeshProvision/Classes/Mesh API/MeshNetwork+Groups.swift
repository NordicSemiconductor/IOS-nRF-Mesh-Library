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
    
    /// Returns the Group with the given Address, or `nil` if no such was found.
    ///
    /// - parameter address: The Group Address.
    /// - returns: The Group with the given Address, or `nil` if no such found.
    func group(withAddress address: MeshAddress) -> Group? {
        return group(withAddress: address.address)
    }
    
    /// Returns the Group with the given Address, or `nil` if no such was found.
    ///
    /// - parameter address: The Group Address.
    /// - returns: The Group with the given Address, or `nil` if no such found.
    func group(withAddress address: Address) -> Group? {
        return groups.first { $0.address.address == address }
    }
    
    /// Adds a new Group to the network.
    ///
    /// If the mesh network already contains a Group with the same address,
    /// this method throws an error.
    ///
    /// Groups with predefined addresses (i.e. All Nodes) cannot be added as
    /// custom groups.
    ///
    /// - parameter group: The Group to be added.
    /// - throws: This method throws an error if a Group with the same address
    ///           already exists in the mesh network, or it is a Special Group.
    func add(group: Group) throws {
        guard !group.address.address.isSpecialGroup else {
            throw MeshNetworkError.invalidAddress
        }
        guard !groups.contains(group) else {
            throw MeshNetworkError.groupAlreadyExists
        }
        group.meshNetwork = self
        groups.append(group)
        timestamp = Date()
    }
    
    /// Removes the given Group from the network.
    ///
    /// The Group must not be in use, i.e. it may not be a parent of
    /// another Group.
    ///
    /// - parameter group: The Group to be removed.
    /// - throws: This method throws ``MeshNetworkError/groupInUse`` when the
    ///           Group is in use in this mesh network.
    func remove(group: Group) throws {
        if group.isUsed {
            throw MeshNetworkError.groupInUse
        }
        if let index = groups.firstIndex(of: group) {
            groups.remove(at: index).meshNetwork = nil
            timestamp = Date()
        }
    }
    
    /// Returns list of Models belonging to any of the Elements in the
    /// network that are subscribed to the given Group.
    ///
    /// - parameter group: The Group to look for.
    /// - returns: List of Models that are subscribed to the given Group.
    func models(subscribedTo group: Group) -> [Model] {
        return nodes.flatMap { $0.elements.models(subscribedTo: group) }
    }
    
}
