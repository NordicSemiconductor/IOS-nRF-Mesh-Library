//
//  MeshModelError.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 22/03/2019.
//

import Foundation

public enum MeshModelError: Error {
    /// Thrown when any allocated range of the new Provisioner overlaps
    /// with existing one.
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
    /// Thrown when the address cannot be assigne as it is being used by
    /// another node.
    case addressNotAvailable
    /// Thrown when the address is of a wrong type.
    case invalidAddress
    /// Thrown when a node cannot be added due to its address not being
    /// inside Provisioner's unicast address range.
    case addressNotInAllocatedRange
    /// Thrown when the requested Provisioner is not in the Mesh Network.
    case provisionerNotInNetwork
    /// Thrown when the range to be allocated is of invalid type.
    case invalidRange
    /// Thrown when the provided key is not 128-bit long.
    case invalidKey
    /// Thrown when trying to remove a key that is being used by some node.
    case keyInUse
    /// Thrown when a new Group is being added with the same address as one
    /// that is already in the network.
    case groupAlreadyExists
    /// Throw when trying to remove a Group that is either a parent of another
    /// Group, or set as publication or subcription address for any Model.
    case groupInUse
    /// Thrown when the given Key Index is not valid.
    case keyIndexOutOfRange
    /// Thrown when Network Key is required to continue with the operation.
    case noNetworkKey
    /// Thrown when Application Key is required to continue with the operation.
    case noApplicationKey
}

public extension MeshModelError {
    
    var localizedDescription: String {
        switch self {
        case .overlappingProvisionerRanges:    return "Overlapping Provisioner ranges"
        case .provisionerUsedInAnotherNetwork: return "Provisioner used in another network"
        case .nodeAlreadyExist:                return "Node with the same UUID already exists in the network"
        case .noAddressAvailable:              return "No address available in Provisioner's range"
        case .addressNotAvailable:             return "Address used by another Node in the network"
        case .invalidAddress:                  return "Invalid address"
        case .addressNotInAllocatedRange:      return "Address outside Provisioner's range"
        case .provisionerNotInNetwork:         return "Provisioner does not belong to the network"
        case .invalidRange:                    return "Invalid range"
        case .invalidKey:                      return "Invalid key: The key must be 128-bit long"
        case .keyInUse:                        return "Cannot remove: Key in use"
        case .groupAlreadyExists:              return "Group with the same address already exists in the network"
        case .groupInUse:                      return "Cannot remove: Group is use"
        case .keyIndexOutOfRange:              return "Key Index out of range"
        case .noNetworkKey:                    return "No Network Key"
        case .noApplicationKey:                return "No Application Key"
        }
    }
    
}
