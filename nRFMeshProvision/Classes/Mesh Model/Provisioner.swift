//
//  Provisioner.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

public class Provisioner: Codable {
    /// 128-bit Device UUID.
    public let uuid: MeshUUID
    /// UTF-8 string, which should be a human readable name of the Provisioner.
    public var provisionerName: String
    /// An array of unicast range objects.
    public internal(set) var allocatedUnicastRange: [AddressRange]
    /// An array of group range objects.
    public internal(set) var allocatedGroupRange:   [AddressRange]
    /// An array of scene range objects.
    public internal(set) var allocatedSceneRange:   [SceneRange]
    
    public init(name: String,
                uuid: UUID,
                allocatedUnicastRange: [AddressRange],
                allocatedGroupRange:   [AddressRange],
                allocatedSceneRange:   [SceneRange]) {
        self.provisionerName = name
        self.uuid = MeshUUID(uuid)
        self.allocatedUnicastRange = allocatedUnicastRange
        self.allocatedGroupRange   = allocatedGroupRange
        self.allocatedSceneRange   = allocatedSceneRange
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
    
    /// Allocates Address range for the Provisioner. This method will
    /// automatically merge ranges if they ovelap, and assign the range
    /// to unicast or group ranges.
    public func allocateRange(_ range: AddressRange) {
        // TODO
    }
    
    /// Allocats Scene range for the Provisioned. This method will
    /// automatically merge ranges if they overlap.
    public func allocateRange(_ range: SceneRange) {
        // TODO
    }
}

public extension Provisioner {
    
    /// Returns true if all ranges have been defined.
    public func isValid() -> Bool {
        return !allocatedUnicastRange.isEmpty && allocatedUnicastRange.isValid
            && !allocatedGroupRange.isEmpty   && allocatedGroupRange.isValid
            && !allocatedSceneRange.isEmpty   && allocatedSceneRange.isValid
    }
    
    /// Returns true if at least one range overlaps with the given Provisioner.
    public func hasOverlappingRanges(with provisioner: Provisioner) -> Bool {
        return hasOverlappingUnicastRanges(with: provisioner)
            || hasOverlappingGroupRanges(with:provisioner)
            || hasOverlappingSceneRanges(with: provisioner)
    }
    
    /// Returns true if at least one Unicast Address range overlaps with address
    /// ranges of the given Provisioner.
    public func hasOverlappingUnicastRanges(with provisioner: Provisioner) -> Bool {
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
    public func hasOverlappingGroupRanges(with provisioner: Provisioner) -> Bool {
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
    public func hasOverlappingSceneRanges(with provisioner: Provisioner) -> Bool {
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
