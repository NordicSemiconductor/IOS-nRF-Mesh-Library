//
//  Provisioner+Ranges.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 08/05/2019.
//

import Foundation

public extension Provisioner {
    
    /// Returns `true` if all defined ranges are valid.
    /// Unicase Address range may not be empty, as it needs to assign addresses
    /// during provisioning.
    var isValid: Bool {
        return allocatedUnicastRange.isUnicastRange
            && allocatedGroupRange.isGroupRange
            && allocatedSceneRange.isValid
            && !allocatedUnicastRange.isEmpty
    }
    
    /// Allocates Unicast Address range for the Provisioner. This method
    /// will automatically merge ranges if they ovelap.
    ///
    /// - parameter range: The new unicast range to allocate.
    /// - throws: The method throws an error when the Provisioner is added
    ///           to the mesh network and the new range overlapps any of
    ///           other Provisioners' ranges, or the range is of invalid type.
    func allocateUnicastAddressRange(_ range: AddressRange) throws {
        // Validate range type.
        guard range.isUnicastRange else {
            throw MeshModelError.invalidRange
        }
        // If the Provisioner is added to the mesh network, check if
        // the new range does not overlap with other Provisioner's ranges.
        if let meshNetwork = meshNetwork {
            for otherProvisioner in meshNetwork.provisioners.filter({ $0 != self }) {
                guard !otherProvisioner.allocatedUnicastRange.overlaps(range) else {
                    throw MeshModelError.overlappingProvisionerRanges
                }
            }
        }
        allocatedUnicastRange += range
    }
    
    /// Allocates the given Unicast Address ranges for the Provisioner.
    /// This method will automatically merge ranges if they ovelap.
    ///
    /// - parameter range: The new unicast ranges to allocate.
    /// - throws: The method throws an error when the Provisioner is added
    ///           to the mesh network and at least one new range overlapps any of
    ///           other Provisioners' ranges, or the range is of invalid type.
    func allocateUnicastAddressRanges(_ ranges: [AddressRange]) throws {
        // Validate ranges type.
        guard ranges.isUnicastRange else {
            throw MeshModelError.invalidRange
        }
        // Check if the ranges don't overlap with other Prvisioners' ranges.
        if let meshNetwork = meshNetwork {
            for otherProvisioner in meshNetwork.provisioners.filter({ $0 != self }) {
                guard !otherProvisioner.allocatedUnicastRange.overlaps(ranges) else {
                    throw MeshModelError.overlappingProvisionerRanges
                }
            }
        }
        allocatedUnicastRange += ranges
    }
    
    /// Allocates Group Address range for the Provisioner. This method
    /// will automatically merge ranges if they ovelap.
    ///
    /// - parameter range: The new group range to allocate.
    /// - throws: The method throws an error when the Provisioner is added
    ///           to the mesh network and the new range overlapps any of
    ///           other Provisioners' ranges, or the range is of invalid type.
    func allocateGroupAddressRange(_ range: AddressRange) throws {
        // Validate range type.
        guard range.isGroupRange else {
            throw MeshModelError.invalidRange
        }
        // If the Provisioner is added to the mesh network, check if
        // the new range does not overlap with other Provisioner's ranges.
        if let meshNetwork = meshNetwork {
            for otherProvisioner in meshNetwork.provisioners.filter({ $0 != self }) {
                guard !otherProvisioner.allocatedGroupRange.overlaps(range) else {
                    throw MeshModelError.overlappingProvisionerRanges
                }
            }
        }
        allocatedGroupRange += range
    }
    
    /// Allocates the given Group Address ranges for the Provisioner.
    /// This method will automatically merge ranges if they ovelap.
    ///
    /// - parameter range: The new group ranges to allocate.
    /// - throws: The method throws an error when the Provisioner is added
    ///           to the mesh network and at least one new range overlapps any of
    ///           other Provisioners' ranges, or the range is of invalid type.
    func allocateGroupAddressRanges(_ ranges: [AddressRange]) throws {
        // Validate ranges type.
        guard ranges.isGroupRange else {
            throw MeshModelError.invalidRange
        }
        // Check if the ranges don't overlap with other Prvisioners' ranges.
        if let meshNetwork = meshNetwork {
            for otherProvisioner in meshNetwork.provisioners.filter({ $0 != self }) {
                guard !otherProvisioner.allocatedGroupRange.overlaps(ranges) else {
                    throw MeshModelError.overlappingProvisionerRanges
                }
            }
        }
        allocatedGroupRange += ranges
    }
    
    /// Allocates Scene range for the Provisioned. This method will
    /// automatically merge ranges if they overlap.
    ///
    /// - parameter range: The new scene range to allocate.
    /// - throws: The method throws an error when the Provisioner is added
    ///           to the mesh network and the new range overlapps any of
    ///           other Provisioners' ranges, or the range is of invalid type.
    func allocateSceneRange(_ range: SceneRange) throws {
        // Validate range type.
        guard range.isValid else {
            throw MeshModelError.invalidRange
        }
        // If the Provisioner is added to the mesh network, check if
        // the new range does not overlap with other Provisioner's ranges.
        if let meshNetwork = meshNetwork {
            for otherProvisioner in meshNetwork.provisioners.filter({ $0 != self }) {
                guard !otherProvisioner.allocatedSceneRange.overlaps(range) else {
                    throw MeshModelError.overlappingProvisionerRanges
                }
            }
        }
        allocatedSceneRange += range
    }
    
    /// Allocates the given Scene ranges for the Provisioner.
    /// This method will automatically merge ranges if they ovelap.
    ///
    /// - parameter range: The new scene ranges to allocate.
    /// - throws: The method throws an error when the Provisioner is added
    ///           to the mesh network and at least one new range overlapps any of
    ///           other Provisioners' ranges, or the range is of invalid type.
    func allocateSceneRanges(_ ranges: [SceneRange]) throws {
        // Validate ranges type.
        guard ranges.isValid else {
            throw MeshModelError.invalidRange
        }
        // Check if the ranges don't overlap with other Prvisioners' ranges.
        if let meshNetwork = meshNetwork {
            for otherProvisioner in meshNetwork.provisioners.filter({ $0 != self }) {
                guard !otherProvisioner.allocatedSceneRange.overlaps(ranges) else {
                    throw MeshModelError.overlappingProvisionerRanges
                }
            }
        }
        allocatedSceneRange += ranges
    }
    
    /// Deallocates the given range from Unicast Address ranges of the
    /// Provisioner. This method does not remove the range instance,
    /// but is able to cut the given range from the allocated ranges.
    ///
    /// To remove all ranges, call this method with
    /// parameter set to `AddressRange.allUnicastAddresses`.
    ///
    /// - parameter range: The range to be deallocated.
    func deallocateUnicastAddressRange(_ range: AddressRange) {
        allocatedUnicastRange -= range
    }
    
    /// Deallocates the given range from Group Address ranges of the
    /// Provisioner. This method does not remove the range instance,
    /// but is able to cut the given range from the allocated ranges.
    ///
    /// To remove all ranges, call this method with
    /// parameter set to `AddressRange.allGroupAddresses`.
    ///
    /// - parameter range: The range to be deallocated.
    func deallocateGroupAddressRange(_ range: AddressRange) {
        allocatedGroupRange -= range
    }
    
    /// Deallocates the given range from Unicast Address ranges of the
    /// Provisioner. This method does not remove the range instance,
    /// but is able to cut the given range from the allocated ranges.
    ///
    /// To remove all ranges, call this method with
    /// parameter set to `SceneRange.allScenes`.
    ///
    /// - parameter range: The range to be deallocated.
    func deallocateSceneRange(_ range: SceneRange) {
        allocatedSceneRange -= range
    }
    
    /// Returns `true` if the count addresses starting from the given one are in
    /// the Provisioner's allocated address ranges.
    ///
    /// The address may be a unicast or group address.
    ///
    /// - parameter address: The first address to be checked.
    /// - parameter count:   Number of subsequent addresses to be checked.
    /// - returns: `True` if the address is in allocated ranges, `false` otherwise.
    func isAddressInAllocatedRange(_ address: Address, elementCount count: UInt8) -> Bool {
        guard address.isUnicast || address.isGroup else {
            return false
        }
        
        let ranges = address.isUnicast ? allocatedUnicastRange : allocatedGroupRange
        for range in ranges {
            if range.contains(address) && range.contains(address + UInt16(count) - 1) {
                return true
            }
        }
        return false
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
            for node in meshNetwork.nodes.filter({ $0.unicastAddress != address }) {
                if node.overlapsWithAddress(address, elementsCount: UInt8(count)) {
                    count = Int(node.unicastAddress - address)
                }
            }
        }
        return count
    }
    
    /// Returns `true` if at least one range overlaps with the given Provisioner.
    ///
    /// - parameter provisioner: The Provisioner to check ranges with.
    /// - returns: `True` if this and the given Provisioner have overlaping ranges,
    ///            `false` otherwise.
    func hasOverlappingRanges(with provisioner: Provisioner) -> Bool {
        return hasOverlappingUnicastRanges(with: provisioner)
            || hasOverlappingGroupRanges(with:provisioner)
            || hasOverlappingSceneRanges(with: provisioner)
    }
    
    /// Returns `true` if at least one Unicast Address range overlaps with address
    /// ranges of the given Provisioner.
    ///
    /// - parameter provisioner: The Provisioner to check ranges with.
    /// - returns: `True` if this and the given Provisioner have overlaping unicast
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
    /// - returns: `True` if this and the given Provisioner have overlaping group
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
    /// - returns: `True` if this and the given Provisioner have overlaping scene
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
