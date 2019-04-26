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
}
