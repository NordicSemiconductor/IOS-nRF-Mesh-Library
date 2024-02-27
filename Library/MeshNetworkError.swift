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

/// A set of generic mesh errors.
public enum MeshNetworkError: Error {
    /// Thrown when any allocated range of the new Provisioner overlaps
    /// with an existing one.
    case overlappingProvisionerRanges
    /// Thrown when trying to add a Provisioner that is already a part
    /// of another mesh network.
    case provisionerUsedInAnotherNetwork
    /// Thrown when a new Provisioner has the same UUID as one node that
    /// is already in the mesh network.
    case nodeAlreadyExist
    /// Thrown when a node cannot be added due to lack of available
    /// addresses in Provisioner's range.
    case noAddressAvailable
    /// Thrown when the address cannot be assigned as it is being used by
    /// another node.
    case addressNotAvailable
    /// Thrown when the address is of a wrong type.
    case invalidAddress
    /// Thrown when a node cannot be added due to its address not being
    /// inside Provisioner's unicast address range.
    case addressNotInAllocatedRange
    /// Thrown when the requested Provisioner is not in the Mesh Network.
    case provisionerNotInNetwork
    /// Thrown when the object cannot be removed.
    case cannotRemove
    /// Thrown when the range to be allocated is of invalid type.
    case invalidRange
    /// Thrown when the provided key is not 128-bit long.
    case invalidKey
    /// Thrown when trying to remove a key that is being used by another Node.
    case keyInUse
    /// Thrown when a new Group is being added with the same address as one
    /// that is already in the network.
    case groupAlreadyExists
    /// Thrown when a new Scene is being added with the same number as one
    /// that is already in the network.
    case sceneAlreadyExists
    /// Thrown when trying to remove a Group that is either a parent of another
    /// Group, or set as publication or subscription address for a Model.
    case groupInUse
    /// Thrown when trying to remove a Scene stored by at least one Scene Register.
    case sceneInUse
    /// Thrown when the given Key Index is not valid.
    case keyIndexOutOfRange
    /// Thrown when Network Key is required to continue with the operation.
    case noNetworkKey
    /// Thrown when Application Key is required to continue with the operation.
    case noApplicationKey
    /// Thrown when trying to send a mesh message before setting up the mesh network.
    case noNetwork
    /// Thrown when setting too small IV Index. The new IV Index must be greater than
    /// or equal to the previous one.
    case ivIndexTooSmall
}

extension MeshNetworkError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .overlappingProvisionerRanges:    return NSLocalizedString("Overlapping Provisioner ranges.", comment: "")
        case .provisionerUsedInAnotherNetwork: return NSLocalizedString("Provisioner used in another network.", comment: "")
        case .nodeAlreadyExist:                return NSLocalizedString("Node with the same UUID already exists in the network.", comment: "")
        case .noAddressAvailable:              return NSLocalizedString("No address available in Provisioner's range.", comment: "")
        case .addressNotAvailable:             return NSLocalizedString("Address used by another Node in the network.", comment: "")
        case .invalidAddress:                  return NSLocalizedString("Invalid address.", comment: "")
        case .addressNotInAllocatedRange:      return NSLocalizedString("Address outside Provisioner's range.", comment: "")
        case .provisionerNotInNetwork:         return NSLocalizedString("Provisioner does not belong to the network.", comment: "")
        case .cannotRemove:                    return NSLocalizedString("Object could not be removed.", comment: "")
        case .invalidRange:                    return NSLocalizedString("Invalid range.", comment: "")
        case .invalidKey:                      return NSLocalizedString("Invalid key: The key must be 128-bit long.", comment: "")
        case .keyInUse:                        return NSLocalizedString("Cannot remove: Key in use.", comment: "")
        case .groupAlreadyExists:              return NSLocalizedString("Group with the same address already exists in the network.", comment: "")
        case .sceneAlreadyExists:              return NSLocalizedString("Scene with the same number already exists in the network.", comment: "")
        case .groupInUse:                      return NSLocalizedString("Cannot remove: Group is use.", comment: "")
        case .sceneInUse:                      return NSLocalizedString("Cannot remove: Scene is use.", comment: "")
        case .keyIndexOutOfRange:              return NSLocalizedString("Key Index out of range.", comment: "")
        case .noNetworkKey:                    return NSLocalizedString("No Network Key.", comment: "")
        case .noApplicationKey:                return NSLocalizedString("No Application Key.", comment: "")
        case .noNetwork:                       return NSLocalizedString("Mesh Network not created.", comment: "")
        case .ivIndexTooSmall:                 return NSLocalizedString("IV Index too small", comment: "")
        }
    }
    
}
