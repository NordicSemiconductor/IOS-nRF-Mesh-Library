//
//  MeshNetwork+Ranges.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 25/04/2019.
//

import Foundation

// MARK: - Ranges validation

public extension MeshNetwork {
    
    /// Checks whether the given range is available for allocation to a new
    /// provisioner.
    ///
    /// - parameter range: The range to be checked.
    /// - returns: `True`, if the range does not overlap with any address
    ///            range already allocated by any Provisioner added to the mesh
    ///            network; `false` otherwise.
    func isRangeAvailableForAllocation(_ range: AddressRange) -> Bool {
        if range.isUnicastRange {
            return !provisioners.contains { $0.allocatedUnicastRange.overlaps(range) }
        }
        if range.isGroupRange {
            return !provisioners.contains { $0.allocatedGroupRange.overlaps(range) }
        }
        return false
    }
    
    /// Checks whether the given range is available for allocation to a new
    /// provisioner.
    ///
    /// - parameter range: The range to be checked.
    /// - returns: `True`, if the range does not overlap with any scene
    ///            range already allocated by any Provisioner added to the mesh
    ///            network; `false` otherwise.
    func isRangeAvailableForAllocation(_ range: SceneRange) -> Bool {
        return range.isValid && !provisioners.contains { $0.allocatedSceneRange.overlaps(range) }
    }
    
    /// Checks whether the given range is available for allocation to the given
    /// provisioner.
    ///
    /// - parameter range: The range to be checked.
    /// - returns: `True`, if the range does not overlap with any address
    ///            range already allocated by any other Provisioner added to the mesh
    ///            network; `false` otherwise.
    func isRange(_ range: AddressRange, availableForAllocationTo provisioner: Provisioner) -> Bool {
        if hasProvisioner(provisioner) {
            if range.isUnicastRange {
                return !provisioners.filter({ $0 != provisioner }).contains { $0.allocatedUnicastRange.overlaps(range) }
            }
            if range.isGroupRange {
                return !provisioners.filter({ $0 != provisioner }).contains { $0.allocatedGroupRange.overlaps(range) }
            }
        }
        return range.isValid
    }
    
    /// Checks whether the given ranges are available for allocation to the given
    /// provisioner.
    ///
    /// - parameter ranges: The array of ranges to be checked.
    /// - returns: `True`, if none of the ranges overlap with any address
    ///            range already allocated by any other Provisioner added to the mesh
    ///            network; `false` otherwise.
    func areRanges(_ ranges: [AddressRange], availableForAllocationTo provisioner: Provisioner) -> Bool {
        if hasProvisioner(provisioner) {
            if ranges.isUnicastRange {
                return !provisioners.filter({ $0 != provisioner }).contains { $0.allocatedUnicastRange.overlaps(ranges) }
            }
            if ranges.isGroupRange {
                return !provisioners.filter({ $0 != provisioner }).contains { $0.allocatedGroupRange.overlaps(ranges) }
            }
        }
        return ranges.isValid
    }
    
    /// Checks whether the given range is available for allocation to a new
    /// provisioner.
    ///
    /// - parameter range: The range to be checked.
    /// - returns: `True`, if the range does not overlap with any scene
    ///            range already allocated by any other Provisioner added to the mesh
    ///            network; `false` otherwise.
    func isRange(_ range: SceneRange, availableForAllocationTo provisioner: Provisioner) -> Bool {
        return range.isValid && !provisioners.filter({ $0 != provisioner }).contains { $0.allocatedSceneRange.overlaps(range) }
    }
    
    /// Checks whether the given ranges are available for allocation to a new
    /// provisioner.
    ///
    /// - parameter range: The array of ranges to be checked.
    /// - returns: `True`, if the none of the ranges overlap with any scene
    ///            range already allocated by any other Provisioner added to the mesh
    ///            network; `false` otherwise.
    func areRanges(_ ranges: [SceneRange], availableForAllocationTo provisioner: Provisioner) -> Bool {
        return ranges.isValid && !provisioners.filter({ $0 != provisioner }).contains { $0.allocatedSceneRange.overlaps(ranges) }
    }
    
}
