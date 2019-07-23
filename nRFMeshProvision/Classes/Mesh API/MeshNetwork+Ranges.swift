//
//  MeshNetwork+Ranges.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 25/04/2019.
//

import Foundation

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
        return range.isValid &&
            !provisioners.contains { $0.allocatedSceneRange.overlaps(range) }
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
                return !provisioners
                    .filter({ $0 != provisioner })
                    .contains { $0.allocatedUnicastRange.overlaps(range) }
            }
            if range.isGroupRange {
                return !provisioners
                    .filter({ $0 != provisioner })
                    .contains { $0.allocatedGroupRange.overlaps(range) }
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
                return !provisioners
                    .filter({ $0 != provisioner })
                    .contains { $0.allocatedUnicastRange.overlaps(ranges) }
            }
            if ranges.isGroupRange {
                return !provisioners
                    .filter({ $0 != provisioner })
                    .contains { $0.allocatedGroupRange.overlaps(ranges) }
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
        return range.isValid &&
            !provisioners
                .filter({ $0 != provisioner })
                .contains { $0.allocatedSceneRange.overlaps(range) }
    }
    
    /// Checks whether the given ranges are available for allocation to a new
    /// provisioner.
    ///
    /// - parameter range: The array of ranges to be checked.
    /// - returns: `True`, if the none of the ranges overlap with any scene
    ///            range already allocated by any other Provisioner added to the mesh
    ///            network; `false` otherwise.
    func areRanges(_ ranges: [SceneRange], availableForAllocationTo provisioner: Provisioner) -> Bool {
        return ranges.isValid &&
            !provisioners
                .filter({ $0 != provisioner })
                .contains { $0.allocatedSceneRange.overlaps(ranges) }
    }
    
    /// Returns the next available Unicast Address range of given size that is
    /// not allocated to any Provisioner. If no range of given size can be found,
    /// a range of maximum available space is returned. If all addresses have
    /// been allocated, `nil` is returned.
    ///
    /// - parameter size: The preferred and maximum size of a range to find.
    /// - returns: The range of given size, a smaller one if such is not available
    ///            or `nil` if all addresses are alread allocated.
    func nextAvailableUnicastAddressRange(ofSize size: UInt16 = Address.maxUnicastAddress) -> AddressRange? {
        let allRangesSorted: [AddressRange] = provisioners
            .reduce([], { ranges, next in ranges + next.allocatedUnicastRange })
            .sorted { $0.lowerBound < $1.lowerBound }
        
        guard let range = nextAvailableRange(ofSize: size, in: Address.minUnicastAddress...Address.maxUnicastAddress,
                                             among: allRangesSorted) else {
                                                return nil
        }
        return AddressRange(range.range)
    }
    
    /// Returns the next available Group Address range of given size that is
    /// not allocated to any Provisioner. If no range of given size can be found,
    /// a range of maximum available space is returned. If all addresses have
    /// been allocated, `nil` is returned.
    ///
    /// - parameter size: The preferred and maximum size of a range to find.
    /// - returns: The range of given size, a smaller one if such is not available
    ///            or `nil` if all addresses are alread allocated.
    func nextAvailableGroupAddressRange(ofSize size: UInt16 = Address.maxGroupAddress) -> AddressRange? {
        let allRangesSorted: [AddressRange] = provisioners
            .reduce([], { ranges, next in ranges + next.allocatedGroupRange })
            .sorted { $0.lowerBound < $1.lowerBound }
        
        guard let range = nextAvailableRange(ofSize: size, in: Address.minGroupAddress...Address.maxGroupAddress,
                                             among: allRangesSorted) else {
                                                return nil
        }
        return AddressRange(range.range)
    }
    
    /// Returns the next available Scene range of given size that is
    /// not allocated to any Provisioner. If no range of given size can be found,
    /// a range of maximum available space is returned. If all scenes have
    /// been allocated, `nil` is returned.
    ///
    /// - parameter size: The preferred and maximum size of a range to find.
    /// - returns: The range of given size, a smaller one if such is not available
    ///            or `nil` if all scenes are alread allocated.
    func nextAvailableSceneRange(ofSize size: UInt16 = Scene.minScene) -> SceneRange? {
        let allRangesSorted: [SceneRange] = provisioners
            .reduce([], { ranges, next in ranges + next.allocatedSceneRange })
            .sorted { $0.lowerBound < $1.lowerBound }
        
        guard let range = nextAvailableRange(ofSize: size, in: Scene.minScene...Scene.maxScene,
                                             among: allRangesSorted) else {
                                                return nil
        }
        return SceneRange(range.range)
    }
    
    /// Returns the next available Group Address range of given size that is
    /// not allocated to any Provisioner. If no range of given size can be found,
    /// a range of maximum available space is returned. If all addresses have
    /// been allocated, `nil` is returned.
    ///
    /// - parameter size: The preferred and maximum size of a range to find.
    /// - parameter bounds: Bounds in which the addresses are valid.
    /// - parameter ranges: Already assigned ranges.
    /// - returns: The range of given size, a smaller one if such is not available
    ///            or `nil` if all addresses are alread allocated.
    private func nextAvailableRange(ofSize size: UInt16, in bounds: ClosedRange<Address>,
                                    among ranges: [RangeObject]) -> RangeObject? {
        var bestRange: RangeObject? = nil
        var lastUpperBound: Address = bounds.lowerBound - 1
        
        // Go through all ranges looking for a gaps.
        for range in ranges {
            // If there is a space available before this range, return it.
            if UInt32(lastUpperBound) + UInt32(size) < range.lowerBound {
                return RangeObject(lastUpperBound + 1...lastUpperBound + size)
            }
            // If the space exists, but it's not as big as requested, compare
            // it with the best range so far and replace if it's bigger.
            if range.lowerBound - lastUpperBound > 1 {
                let newRange = RangeObject(lastUpperBound + 1...range.lowerBound - 1)
                if bestRange == nil || newRange.count > bestRange!.count {
                    bestRange = newRange
                }
            }
            lastUpperBound = range.upperBound
        }
        
        // If if we didn't return earlier, check after the last range.
        if UInt32(lastUpperBound) + UInt32(size) < bounds.upperBound {
            return RangeObject(lastUpperBound + 1...lastUpperBound + size - 1)
        }
        
        // The gap of requested size hasn't been found. Return the best found.
        return bestRange
    }
    
}
