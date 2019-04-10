//
//  Provisioner.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

public class Provisioner: Codable {
    
    /// 128-bit Device UUID.
    internal let provisionerUuid: MeshUUID
    /// Random 128-bit UUID allows differentiation among multiple mesh networks.
    public var uuid: UUID {
        return provisionerUuid.uuid
    }
    /// UTF-8 string, which should be a human readable name of the Provisioner.
    public var provisionerName: String
    /// An array of unicast range objects.
    public internal(set) var allocatedUnicastRange: [AddressRange]
    /// An array of group range objects.
    public internal(set) var allocatedGroupRange:   [AddressRange]
    /// An array of scene range objects.
    public internal(set) var allocatedSceneRange:   [SceneRange]
    
    private enum CodingKeys: String, CodingKey {
        case provisionerUuid = "uuid"
        case provisionerName
        case allocatedUnicastRange
        case allocatedGroupRange
        case allocatedSceneRange
    }
    
    public init(name: String,
                uuid: UUID,
                allocatedUnicastRange: [AddressRange],
                allocatedGroupRange:   [AddressRange],
                allocatedSceneRange:   [SceneRange]) {
        self.provisionerName = name
        self.provisionerUuid = MeshUUID(uuid)
        self.allocatedUnicastRange = allocatedUnicastRange.merged()
        self.allocatedGroupRange   = allocatedGroupRange.merged()
        self.allocatedSceneRange   = allocatedSceneRange.merged()
    }
    
    public convenience init(name: String,
                            allocatedUnicastRange: [AddressRange],
                            allocatedGroupRange:   [AddressRange],
                            allocatedSceneRange:   [SceneRange]) {
        self.init(name: name,
                  uuid: UUID(),
                  allocatedUnicastRange: allocatedUnicastRange,
                  allocatedGroupRange:   allocatedGroupRange,
                  allocatedSceneRange:   allocatedSceneRange
        )
    }
    
    public convenience init(name: String) {
        self.init(name: name,
                  uuid: UUID(),
                  allocatedUnicastRange: [AddressRange.allUnicastAddresses],
                  allocatedGroupRange:   [AddressRange.allGroupAddresses],
                  allocatedSceneRange:   [SceneRange.allScenes]
        )
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        provisionerName = try container.decode(String.self, forKey: .provisionerName)
        provisionerUuid = try container.decode(MeshUUID.self, forKey: .provisionerUuid)
        allocatedUnicastRange = try container.decode([AddressRange].self, forKey: .allocatedUnicastRange).merged()
        allocatedGroupRange = try container.decode([AddressRange].self, forKey: .allocatedGroupRange).merged()
        allocatedSceneRange = try container.decode([SceneRange].self, forKey: .allocatedSceneRange).merged()
    }
}

// MARK: - Public API

public extension Provisioner {
    
    /// Returns true if all ranges have been defined.
    var isValid: Bool {
        return !allocatedUnicastRange.isEmpty && allocatedUnicastRange.isValid
            && !allocatedGroupRange.isEmpty   && allocatedGroupRange.isValid
            && !allocatedSceneRange.isEmpty   && allocatedSceneRange.isValid
    }
    
    /// Allocates Unicast Address range for the Provisioner. This method
    /// will automatically merge ranges if they ovelap.
    ///
    /// - parameter range: The new unicast range to allocate.
    func allocateUnicastRange(_ range: AddressRange) {
        if range.isUnicastRange {
            allocatedUnicastRange.append(range)
            allocatedUnicastRange.merge()
        }
        // else,
        //     ignore invalid range.
    }
    
    /// Allocates Group Address range for the Provisioner. This method
    /// will automatically merge ranges if they ovelap.
    ///
    /// - parameter range: The new group range to allocate.
    func allocateGroupRange(_ range: AddressRange) {
        if range.isGroupRange {
            allocatedGroupRange.append(range)
            allocatedGroupRange.merge()
        }
        // else,
        //     ignore invalid range.
    }
    
    /// Allocates Scene range for the Provisioned. This method will
    /// automatically merge ranges if they overlap.
    ///
    /// - parameter range: The new range to allocate.
    func allocateRange(_ range: SceneRange) {
        if range.isValid {
            allocatedSceneRange.append(range)
            allocatedSceneRange.merge()
        }
        // else
        //    ignore invalid range.
    }
    
    /// Reallocates Unicast Address ranges for the Provisioned. This method
    /// will automatically merge ranges if they overlap.
    ///
    /// - parameter ranges: The new array of ranges to allocate.
    func reallocateUnicastAddressRanges(_ ranges: [AddressRange]) {
        allocatedUnicastRange.removeAll()
        ranges.forEach { range in
            if range.isUnicastRange {
                allocatedUnicastRange.append(range)
            }
            // else
            //    ignore invalid range.
        }
        allocatedUnicastRange.merge()
    }
    
    /// Reallocates Group Address ranges for the Provisioned. This method
    /// will automatically merge ranges if they overlap.
    ///
    /// - parameter ranges: The new array of ranges to allocate.
    func reallocateGroupAddressRanges(_ ranges: [AddressRange]) {
        allocatedGroupRange.removeAll()
        ranges.forEach { range in
            if range.isGroupRange {
                allocatedGroupRange.append(range)
            }
            // else
            //    ignore invalid range.
        }
        allocatedGroupRange.merge()
    }
    
    /// Reallocates Scene ranges for the Provisioned. This method will
    /// automatically merge ranges if they overlap.
    ///
    /// - parameter ranges: The new array of ranges to allocate.
    func reallocateSceneRanges(_ ranges: [SceneRange]) {
        allocatedSceneRange.removeAll()
        ranges.forEach { range in
            if range.isValid {
                allocatedSceneRange.append(range)
            }
            // else
            //    ignore invalid range.
        }
        allocatedSceneRange.merge()
    }
    
    /// Returns true if the count addresses starting from the given one are in
    /// the Provisioner's allocated address ranges.
    /// The address may be a unicast or group address.
    ///
    /// - parameter address: The first address to be checked.
    /// - parameter count:   Number of subsequent addresses to be checked.
    /// - returns: `True` if the address is in allocated ranges, `false` otherwise.
    func isInAllocatedRange(_ address: Address, count: UInt16 = 1) -> Bool {
        guard address.isUnicast || address.isGroup else {
            return false
        }
        
        let ranges = address.isUnicast ? allocatedUnicastRange : allocatedGroupRange
        for range in ranges {
            if range.contains(address) && range.contains(address + count - 1) {
                return true
            }
        }
        return false
    }
    
    /// Returns true if at least one range overlaps with the given Provisioner.
    ///
    /// - parameter provisioner: The Provisioner to check ranges with.
    /// - returns: `True` if this and the given Provisioner have overlaping ranges,
    ///            `false` otherwise.
    func hasOverlappingRanges(with provisioner: Provisioner) -> Bool {
        return hasOverlappingUnicastRanges(with: provisioner)
            || hasOverlappingGroupRanges(with:provisioner)
            || hasOverlappingSceneRanges(with: provisioner)
    }
    
    /// Returns true if at least one Unicast Address range overlaps with address
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
    
    /// Returns true if at least one Group Address range overlaps with address
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
    
    /// Returns true if at least one Scene range overlaps with scene ranges of
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

// MARK: - Private API

extension Provisioner {
    
    /// Returns the first allocated address that is greater or equal to
    /// the given one from the allocated ranges.
    ///
    /// - parameter address: The lower bound of the look-up address.
    /// - returns: The address found, or nil if one cound not be found
    ///            with given restrictions.
    func firstAllocatedUnicastAddress(greaterOrEqualTo address: Address = Address.minUnicastAddress) -> Address? {
        for range in allocatedUnicastRange {
            if range.lowAddress >= address || range.contains(address) {
                return address
            }
        }
        return nil
    }
    
}

// MARK: - Operators

extension Provisioner: Equatable {
    
    public static func == (lhs: Provisioner, rhs: Provisioner) -> Bool {
        return lhs.uuid    == rhs.uuid
    }
    
    public static func != (lhs: Provisioner, rhs: Provisioner) -> Bool {
        return lhs.uuid != rhs.uuid
    }
    
}
