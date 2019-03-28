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
    /// Thrown when a Provisioner does not have all required ranges
    /// allocated.
    case provisionerRangesNotAllocated
    /// Thrown when a new Provisioner has the same UUID as one node that
    /// is already in the mesh network.
    case nodeAlreadyExist
    /// Thrown when a node cannot be added due to lack of available
    /// addresses in Provisioner's range.
    case noAddressAvailable
}
