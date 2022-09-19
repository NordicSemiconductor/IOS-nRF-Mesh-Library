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

public extension Provisioner {
    
    /// Returns `true` if all defined ranges are valid.
    ///
    /// The Unicast Address range may not be empty, as it needs to assign addresses
    /// during provisioning.
    var isValid: Bool {
        return allocatedUnicastRange.isUnicastRange
            && allocatedGroupRange.isGroupRange
            && allocatedSceneRange.isValid
            && !allocatedUnicastRange.isEmpty
    }
    
    /// Allocates Unicast Address range for the Provisioner. This method
    /// will automatically merge ranges if they overlap.
    ///
    /// - parameter range: The new unicast range to allocate.
    /// - throws: The method throws an error when the Provisioner is added
    ///           to the mesh network and the new range overlaps any of
    ///           other Provisioners' ranges, or the range is of invalid type.
    func allocate(unicastAddressRange range: AddressRange) throws {
        // Validate range type.
        guard range.isUnicastRange else {
            throw MeshNetworkError.invalidRange
        }
        // If the Provisioner is added to the mesh network, check if
        // the new range does not overlap with other Provisioner's ranges.
        if let meshNetwork = meshNetwork {
            guard meshNetwork.isRange(range, availableForAllocationTo: self) else {
                throw MeshNetworkError.overlappingProvisionerRanges
            }
        }
        allocatedUnicastRange += range
    }
    
    /// Allocates Unicast Address range for the Provisioner. This method
    /// will automatically merge ranges if they overlap.
    ///
    /// - parameter range: The new unicast range to allocate.
    /// - throws: The method throws an error when the Provisioner is added
    ///           to the mesh network and the new range overlaps any of
    ///           other Provisioners' ranges, or the range is of invalid type.
    @available(*, deprecated, renamed: "allocate(unicastAddressRange:)")
    func allocateUnicastAddressRange(_ range: AddressRange) throws {
        try allocate(unicastAddressRange: range)
    }
    
    /// Allocates the given Unicast Address ranges for the Provisioner.
    /// This method will automatically merge ranges if they overlap.
    ///
    /// - parameter range: The new unicast ranges to allocate.
    /// - throws: The method throws an error when the Provisioner is added
    ///           to the mesh network and at least one new range overlaps any of
    ///           other Provisioners' ranges, or the range is of invalid type.
    func allocate(unicastAddressRanges ranges: [AddressRange]) throws {
        // Validate ranges type.
        guard ranges.isUnicastRange else {
            throw MeshNetworkError.invalidRange
        }
        // Check if the ranges don't overlap with other Provisioners' ranges.
        if let meshNetwork = meshNetwork {
            guard meshNetwork.areRanges(ranges, availableForAllocationTo: self) else {
                throw MeshNetworkError.overlappingProvisionerRanges
            }
        }
        allocatedUnicastRange += ranges
    }
    
    /// Allocates the given Unicast Address ranges for the Provisioner.
    /// This method will automatically merge ranges if they overlap.
    ///
    /// - parameter range: The new unicast ranges to allocate.
    /// - throws: The method throws an error when the Provisioner is added
    ///           to the mesh network and at least one new range overlaps any of
    ///           other Provisioners' ranges, or the range is of invalid type.
    @available(*, deprecated, renamed: "allocate(unicastAddressRanges:)")
    func allocateUnicastAddressRanges(_ ranges: [AddressRange]) throws {
        try allocate(unicastAddressRanges: ranges)
    }
    
    /// Allocates Group Address range for the Provisioner. This method
    /// will automatically merge ranges if they overlap.
    ///
    /// - parameter range: The new group range to allocate.
    /// - throws: The method throws an error when the Provisioner is added
    ///           to the mesh network and the new range overlaps any of
    ///           other Provisioners' ranges, or the range is of invalid type.
    func allocate(groupAddressRange range: AddressRange) throws {
        // Validate range type.
        guard range.isGroupRange else {
            throw MeshNetworkError.invalidRange
        }
        // If the Provisioner is added to the mesh network, check if
        // the new range does not overlap with other Provisioner's ranges.
        if let meshNetwork = meshNetwork {
            guard meshNetwork.isRange(range, availableForAllocationTo: self) else {
                throw MeshNetworkError.overlappingProvisionerRanges
            }
        }
        allocatedGroupRange += range
    }
    
    /// Allocates Group Address range for the Provisioner. This method
    /// will automatically merge ranges if they overlap.
    ///
    /// - parameter range: The new group range to allocate.
    /// - throws: The method throws an error when the Provisioner is added
    ///           to the mesh network and the new range overlaps any of
    ///           other Provisioners' ranges, or the range is of invalid type.
    @available(*, deprecated, renamed: "allocate(groupAddressRange:)")
    func allocateGroupAddressRange(_ range: AddressRange) throws {
        try allocate(groupAddressRange: range)
    }
    
    /// Allocates the given Group Address ranges for the Provisioner.
    /// This method will automatically merge ranges if they overlap.
    ///
    /// - parameter range: The new group ranges to allocate.
    /// - throws: The method throws an error when the Provisioner is added
    ///           to the mesh network and at least one new range overlaps any of
    ///           other Provisioners' ranges, or the range is of invalid type.
    func allocate(groupAddressRanges ranges: [AddressRange]) throws {
        // Validate ranges type.
        guard ranges.isGroupRange else {
            throw MeshNetworkError.invalidRange
        }
        // Check if the ranges don't overlap with other Provisioners' ranges.
        if let meshNetwork = meshNetwork {
            guard meshNetwork.areRanges(ranges, availableForAllocationTo: self) else {
                throw MeshNetworkError.overlappingProvisionerRanges
            }
        }
        allocatedGroupRange += ranges
    }
    
    /// Allocates the given Group Address ranges for the Provisioner.
    /// This method will automatically merge ranges if they overlap.
    ///
    /// - parameter range: The new group ranges to allocate.
    /// - throws: The method throws an error when the Provisioner is added
    ///           to the mesh network and at least one new range overlaps any of
    ///           other Provisioners' ranges, or the range is of invalid type.
    @available(*, deprecated, renamed: "allocate(groupAddressRanges:)")
    func allocateGroupAddressRanges(_ ranges: [AddressRange]) throws {
        try allocate(groupAddressRanges: ranges)
    }
    
    /// Allocates Scene range for the Provisioned. This method will
    /// automatically merge ranges if they overlap.
    ///
    /// - parameter range: The new scene range to allocate.
    /// - throws: The method throws an error when the Provisioner is added
    ///           to the mesh network and the new range overlaps any of
    ///           other Provisioners' ranges, or the range is of invalid type.
    func allocate(sceneRange range: SceneRange) throws {
        // Validate range type.
        guard range.isValid else {
            throw MeshNetworkError.invalidRange
        }
        // If the Provisioner is added to the mesh network, check if
        // the new range does not overlap with other Provisioner's ranges.
        if let meshNetwork = meshNetwork {
            guard meshNetwork.isRange(range, availableForAllocationTo: self) else {
                throw MeshNetworkError.overlappingProvisionerRanges
            }
        }
        allocatedSceneRange += range
    }
    
    /// Allocates Scene range for the Provisioned. This method will
    /// automatically merge ranges if they overlap.
    ///
    /// - parameter range: The new scene range to allocate.
    /// - throws: The method throws an error when the Provisioner is added
    ///           to the mesh network and the new range overlaps any of
    ///           other Provisioners' ranges, or the range is of invalid type.
    @available(*, deprecated, renamed: "allocate(sceneRange:)")
    func allocateSceneRange(_ range: SceneRange) throws {
        try allocate(sceneRange: range)
    }
    
    /// Allocates the given Scene ranges for the Provisioner.
    /// This method will automatically merge ranges if they overlap.
    ///
    /// - parameter range: The new scene ranges to allocate.
    /// - throws: The method throws an error when the Provisioner is added
    ///           to the mesh network and at least one new range overlaps any of
    ///           other Provisioners' ranges, or the range is of invalid type.
    func allocate(sceneRanges ranges: [SceneRange]) throws {
        // Validate ranges type.
        guard ranges.isValid else {
            throw MeshNetworkError.invalidRange
        }
        // Check if the ranges don't overlap with other Provisioners' ranges.
        if let meshNetwork = meshNetwork {
            guard meshNetwork.areRanges(ranges, availableForAllocationTo: self) else {
                throw MeshNetworkError.overlappingProvisionerRanges
            }
        }
        allocatedSceneRange += ranges
    }
    
    /// Allocates the given Scene ranges for the Provisioner.
    /// This method will automatically merge ranges if they overlap.
    ///
    /// - parameter range: The new scene ranges to allocate.
    /// - throws: The method throws an error when the Provisioner is added
    ///           to the mesh network and at least one new range overlaps any of
    ///           other Provisioners' ranges, or the range is of invalid type.
    @available(*, deprecated, renamed: "allocate(sceneRanges:)")
    func allocateSceneRanges(_ ranges: [SceneRange]) throws {
        try allocate(sceneRanges: ranges)
    }
    
    /// Deallocates the given range from Unicast Address ranges of the
    /// Provisioner. This method does not remove the range instance,
    /// but is able to cut the given range from the allocated ranges.
    ///
    /// To remove all ranges, call this method with
    /// parameter set to ``AddressRange/allUnicastAddresses``.
    ///
    /// - parameter range: The range to be deallocated.
    func deallocate(unicastAddressRange range: AddressRange) {
        allocatedUnicastRange -= range
    }
    
    /// Deallocates the given range from Unicast Address ranges of the
    /// Provisioner. This method does not remove the range instance,
    /// but is able to cut the given range from the allocated ranges.
    ///
    /// To remove all ranges, call this method with
    /// parameter set to ``AddressRange/allUnicastAddresses``.
    ///
    /// - parameter range: The range to be deallocated.
    @available(*, deprecated, renamed: "deallocate(unicastAddressRange:)")
    func deallocateUnicastAddressRange(_ range: AddressRange) {
        deallocate(unicastAddressRange: range)
    }
    
    /// Deallocates the given range from Group Address ranges of the
    /// Provisioner. This method does not remove the range instance,
    /// but is able to cut the given range from the allocated ranges.
    ///
    /// To remove all ranges, call this method with
    /// parameter set to ``AddressRange/allGroupAddresses``.
    ///
    /// - parameter range: The range to be deallocated.
    func deallocate(groupAddressRange range: AddressRange) {
        allocatedGroupRange -= range
    }
    
    /// Deallocates the given range from Group Address ranges of the
    /// Provisioner. This method does not remove the range instance,
    /// but is able to cut the given range from the allocated ranges.
    ///
    /// To remove all ranges, call this method with
    /// parameter set to ``AddressRange/allGroupAddresses``.
    ///
    /// - parameter range: The range to be deallocated.
    @available(*, deprecated, renamed: "deallocate(groupAddressRange:)")
    func deallocateGroupAddressRange(_ range: AddressRange) {
        deallocate(groupAddressRange: range)
    }
    
    /// Deallocates the given range from Unicast Address ranges of the
    /// Provisioner. This method does not remove the range instance,
    /// but is able to cut the given range from the allocated ranges.
    ///
    /// To remove all ranges, call this method with
    /// parameter set to ``SceneRange/allScenes``.
    ///
    /// - parameter range: The range to be deallocated.
    func deallocate(sceneRange range: SceneRange) {
        allocatedSceneRange -= range
    }
    
    /// Deallocates the given range from Unicast Address ranges of the
    /// Provisioner. This method does not remove the range instance,
    /// but is able to cut the given range from the allocated ranges.
    ///
    /// To remove all ranges, call this method with
    /// parameter set to ``SceneRange/allScenes``.
    ///
    /// - parameter range: The range to be deallocated.
    @available(*, deprecated, renamed: "deallocate(sceneRange:)")
    func deallocateSceneRange(_ range: SceneRange) {
        deallocate(sceneRange: range)
    }
    
    /// Returns whether given address range is within any of the ranges allocated
    /// to the Provisioner.
    ///
    /// The address may be a Unicast or a Group Address range.
    ///
    /// - parameters:
    ///   - range: The address range to be checked.
    /// - returns: `True` if the address is in allocated ranges, `false` otherwise.
    func hasAllocated(addressRange range: AddressRange) -> Bool {
        guard range.isUnicastRange || range.isGroupRange else {
            return false
        }
        
        let ranges = range.isUnicastRange ? allocatedUnicastRange : allocatedGroupRange
        return ranges.contains(range)
    }
    
    /// Returns whether the Scene is in the Provisioner's allocated scene ranges.
    ///
    /// - parameter scene: The scene to be checked.
    /// - returns: `True` if the scene is in allocated ranges, `false` otherwise.
    func hasAllocated(sceneNumber scene: SceneNumber) -> Bool {
        guard scene.isValidSceneNumber else {
            return false
        }
        return allocatedSceneRange.contains(scene)
    }
    
    /// Returns whether the count addresses starting from the given one are in
    /// the Provisioner's allocated address ranges.
    ///
    /// The address may be a unicast or group address.
    ///
    /// - parameters:
    ///   - address: The first address to be checked.
    ///   - count:   Number of subsequent addresses to be checked.
    /// - returns: `True` if the address is in allocated ranges, `false` otherwise.
    @available(*, deprecated, renamed: "hasAllocated(addressRange:)")
    func isAddressInAllocatedRange(_ address: Address, elementCount count: UInt8) -> Bool {
        let range = AddressRange(from: address, elementsCount: count)
        return hasAllocated(addressRange: range)
    }
    
    /// Returns whether the Scene is in the Provisioner's allocated scene ranges.
    ///
    /// - parameter scene: The scene to be checked.
    /// - returns: `True` if the scene is in allocated ranges, `false` otherwise.
    @available(*, deprecated, renamed: "hasAllocated(sceneNumber:)")
    func isSceneInAllocatedRange(_ scene: SceneNumber) -> Bool {
        guard scene.isValidSceneNumber else {
            return false
        }
        return allocatedSceneRange.contains(scene)
    }
    
    /// List of all Scenes which numbers are in the Provisioner's allocated scene
    /// ranges.
    var scenes: [Scene] {
        return meshNetwork?.scenes
            .filter { allocatedSceneRange.contains($0.number) } ?? []
    }
    
    /// Returns the maximum number of Elements that can be assigned to a Node
    /// with given Unicast Address.
    ///
    /// This method makes sure that the addresses are in a single Unicast Address
    /// range allocated to the Provisioner and are not already assigned to any
    /// other Node.
    ///
    /// - parameter address: The Node address to check.
    /// - returns: The maximum number of Elements that the Node can have before
    ///            the addresses go out of Provisioner's range, or will overlap
    ///            an existing Node.
    func maxElementCount(for address: Address) -> Int {
        var count = 0
        guard address.isUnicast else {
            return count
        }
        // Check the maximum number of Elements that fit inside a single range.
        for range in allocatedUnicastRange {
            if range.contains(address) {
                count = Int(min(range.highAddress - address + 1, UInt16(UInt8.max))) // This must fit in UInt8.
                break
            }
        }
        // The requested address is not in Provisioner's range.
        guard count > 0 else {
            return 0
        }
        // If the Provisioner is added to a network,
        if let meshNetwork = meshNetwork {
            let otherNodes = meshNetwork.nodes.filter { $0.primaryUnicastAddress != address }
            let range = AddressRange(from: address, elementsCount: UInt8(count))
            for node in otherNodes {
                if node.contains(elementsWithAddressesOverlapping: range) {
                    count = Int(node.primaryUnicastAddress - address)
                }
            }
        }
        return count
    }
    
    /// Returns `true` if at least one range overlaps with the given Provisioner.
    ///
    /// - parameter provisioner: The Provisioner to check ranges with.
    /// - returns: `True` if this and the given Provisioner have overlapping ranges,
    ///            `false` otherwise.
    func hasOverlappingRanges(with provisioner: Provisioner) -> Bool {
        return hasOverlappingUnicastRanges(with: provisioner)
            || hasOverlappingGroupRanges(with: provisioner)
            || hasOverlappingSceneRanges(with: provisioner)
    }
    
    /// Returns `true` if at least one Unicast Address range overlaps with address
    /// ranges of the given Provisioner.
    ///
    /// - parameter provisioner: The Provisioner to check ranges with.
    /// - returns: `True` if this and the given Provisioner have overlapping unicast
    ///            ranges, `false` otherwise.
    func hasOverlappingUnicastRanges(with provisioner: Provisioner) -> Bool {
        // Verify Unicast ranges
        for range in allocatedUnicastRange {
            for other in provisioner.allocatedUnicastRange {
                if range.overlaps(other) {
                    return true
                }
            }
        }
        return false
    }
    
    /// Returns `true` if at least one Group Address range overlaps with address
    /// ranges of the given Provisioner.
    ///
    /// - parameter provisioner: The Provisioner to check ranges with.
    /// - returns: `True` if this and the given Provisioner have overlapping group
    ///            ranges, `false` otherwise.
    func hasOverlappingGroupRanges(with provisioner: Provisioner) -> Bool {
        // Verify Group ranges
        for range in allocatedGroupRange {
            for other in provisioner.allocatedGroupRange {
                if range.overlaps(other) {
                    return true
                }
            }
        }
        return false
    }
    
    /// Returns `true` if at least one Scene range overlaps with scene ranges of
    /// the given Provisioner.
    ///
    /// - parameter provisioner: The Provisioner to check ranges with.
    /// - returns: `True` if this and the given Provisioner have overlapping scene
    ///            ranges, `false` otherwise.
    func hasOverlappingSceneRanges(with provisioner: Provisioner) -> Bool {
        // Verify Scene ranges
        for range in allocatedSceneRange {
            for other in provisioner.allocatedSceneRange {
                if range.overlaps(other) {
                    return true
                }
            }
        }
        return false
    }
    
}
