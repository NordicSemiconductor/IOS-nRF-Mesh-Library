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
    
    /// Checks whether the given range is available for allocation to a new
    /// Provisioner.
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
    
    /// Checks whether the given ranges are available for allocation to a new
    /// Provisioner.
    ///
    /// - parameter ranges: The ranges to be checked.
    /// - returns: `True`, if the ranges do not overlap with any address
    ///            range already allocated by any Provisioner added to the mesh
    ///            network; `false` otherwise.
    func areRangesAvailableForAllocation(_ ranges: [AddressRange]) -> Bool {
        for range in ranges {
            if !isRangeAvailableForAllocation(range) {
                return false
            }
        }
        return true
    }
    
    /// Checks whether the given range is available for allocation to a new
    /// Provisioner.
    ///
    /// - parameter range: The range to be checked.
    /// - returns: `True`, if the range does not overlap with any scene
    ///            range already allocated by any Provisioner added to the mesh
    ///            network; `false` otherwise.
    func isRangeAvailableForAllocation(_ range: SceneRange) -> Bool {
        return range.isValid &&
            !provisioners.contains { $0.allocatedSceneRange.overlaps(range) }
    }
    
    /// Checks whether the given ranges are available for allocation to a new
    /// Provisioner.
    ///
    /// - parameter ranges: The ranges to be checked.
    /// - returns: `True`, if the ranges do not overlap with any address
    ///            range already allocated by any Provisioner added to the mesh
    ///            network; `false` otherwise.
    func areRangesAvailableForAllocation(_ ranges: [SceneRange]) -> Bool {
        for range in ranges {
            if !isRangeAvailableForAllocation(range) {
                return false
            }
        }
        return true
    }
    
    /// Checks whether the given range is available for allocation to the given
    /// Provisioner.
    ///
    /// - parameters:
    ///   - ranges:      The range to be checked.
    ///   - provisioner: The Provisioner to check the allocation for.   
    /// - returns: `True`, if the range does not overlap with any address
    ///            range already allocated by any other Provisioner added to the mesh
    ///            network; `false` otherwise.
    func isRange(_ range: AddressRange, availableForAllocationTo provisioner: Provisioner) -> Bool {
        if range.isUnicastRange {
            return !provisioners
                .filter { $0 != provisioner }
                .contains { $0.allocatedUnicastRange.overlaps(range) }
        }
        if range.isGroupRange {
            return !provisioners
                .filter { $0 != provisioner }
                .contains { $0.allocatedGroupRange.overlaps(range) }
        }
        return false
    }
    
    /// Checks whether the given ranges are available for allocation to the given
    /// Provisioner.
    ///
    /// - parameters:
    ///   - ranges:      The array of ranges to be checked.
    ///   - provisioner: The Provisioner to check the allocation for.
    /// - returns: `True`, if none of the ranges overlap with any address
    ///            range already allocated by any other Provisioner added to the mesh
    ///            network; `false` otherwise.
    func areRanges(_ ranges: [AddressRange], availableForAllocationTo provisioner: Provisioner) -> Bool {
        if ranges.isUnicastRange {
            return !provisioners
                .filter { $0 != provisioner }
                .contains { $0.allocatedUnicastRange.overlaps(ranges) }
        }
        if ranges.isGroupRange {
            return !provisioners
                .filter { $0 != provisioner }
                .contains { $0.allocatedGroupRange.overlaps(ranges) }
        }
        return false
    }
    
    /// Checks whether the given range is available for allocation to a new
    /// Provisioner.
    ///
    /// - parameters:
    ///   - ranges:      The range to be checked.
    ///   - provisioner: The Provisioner to check the allocation for.
    /// - returns: `True`, if the range does not overlap with any scene
    ///            range already allocated by any other Provisioner added to the mesh
    ///            network; `false` otherwise.
    func isRange(_ range: SceneRange, availableForAllocationTo provisioner: Provisioner) -> Bool {
        if range.isValid {
            return !provisioners
                .filter { $0 != provisioner }
                .contains { $0.allocatedSceneRange.overlaps(range) }
        }
        return false
    }
    
    /// Checks whether the given ranges are available for allocation to a new
    /// Provisioner.
    ///
    /// - parameters:
    ///   - ranges:      The array of ranges to be checked.
    ///   - provisioner: The Provisioner to check the allocation for.
    /// - returns: `True`, if the none of the ranges overlap with any scene
    ///            range already allocated by any other Provisioner added to the mesh
    ///            network; `false` otherwise.
    func areRanges(_ ranges: [SceneRange], availableForAllocationTo provisioner: Provisioner) -> Bool {
        if ranges.isValid {
            return !provisioners
                .filter { $0 != provisioner }
                .contains { $0.allocatedSceneRange.overlaps(ranges) }
        }
        return false
    }
    
    /// Returns the next available Unicast Address range of given size that is
    /// not allocated to any Provisioner. If no range of given size can be found,
    /// a range of maximum available space is returned. If all addresses have
    /// been allocated, `nil` is returned.
    ///
    /// - parameter size: The preferred and maximum size of a range to find.
    /// - returns: The range of given size, a smaller one if such is not available
    ///            or `nil` if all addresses are already allocated.
    func nextAvailableUnicastAddressRange(ofSize size: UInt16 = .maxUnicastAddress - .minUnicastAddress + 1) -> AddressRange? {
        let allRangesSorted: [AddressRange] = provisioners
            .reduce([]) { ranges, next in ranges + next.allocatedUnicastRange }
            .sorted { $0.lowerBound < $1.lowerBound }
        
        guard let range = nextAvailableRange(ofSize: size,
                                             in: Address.minUnicastAddress...Address.maxUnicastAddress,
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
    ///            or `nil` if all addresses are already allocated.
    func nextAvailableGroupAddressRange(ofSize size: UInt16 = .maxGroupAddress - .minGroupAddress + 1) -> AddressRange? {
        let allRangesSorted: [AddressRange] = provisioners
            .reduce([]) { ranges, next in ranges + next.allocatedGroupRange }
            .sorted { $0.lowerBound < $1.lowerBound }
        
        guard let range = nextAvailableRange(ofSize: size,
                                             in: Address.minGroupAddress...Address.maxGroupAddress,
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
    ///            or `nil` if all scenes are already allocated.
    func nextAvailableSceneRange(ofSize size: UInt16 = .maxScene - .minScene + 1) -> SceneRange? {
        let allRangesSorted: [SceneRange] = provisioners
            .reduce([]) { ranges, next in ranges + next.allocatedSceneRange }
            .sorted { $0.lowerBound < $1.lowerBound }
        
        guard let range = nextAvailableRange(ofSize: size,
                                             in: SceneNumber.minScene...SceneNumber.maxScene,
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
    ///            or `nil` if all addresses are already allocated.
    private func nextAvailableRange(ofSize size: UInt16, in bounds: ClosedRange<Address>,
                                    among ranges: [RangeObject]) -> RangeObject? {
        guard size > 0 else {
            return nil
        }
        
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
            let availableSize = range.lowerBound - lastUpperBound - 1
            if availableSize > 0 {
                let newRange = RangeObject(lastUpperBound + 1...lastUpperBound + availableSize)
                if bestRange == nil || newRange.count > bestRange!.count {
                    bestRange = newRange
                }
            }
            lastUpperBound = range.upperBound
        }
        // If if we didn't return earlier, check after the last range.
        let availableSize = bounds.upperBound - lastUpperBound
        let bestSize = UInt16(bestRange?.count ?? 0)
        if availableSize > bestSize {
            return RangeObject(lastUpperBound + 1...lastUpperBound + min(size, availableSize))
        }
        
        // The gap of requested size hasn't been found. Return the best found.
        return bestRange
    }
    
}
