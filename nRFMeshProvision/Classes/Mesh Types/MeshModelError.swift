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
}
