//
//  MeshNetworkManager+ProxyFilter.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 03/09/2019.
//

import Foundation

public enum ProxyFilerType: UInt8 {
    /// A white list filter has an associated white list, which is a list of
    /// destination addresses that are of interest for the Proxy Client.
    /// The white list filter blocks all destination addresses except those
    /// that have been added to the white list.
    case whitelist = 0x00
    /// A black list filter has an associated black list, which is a list of
    /// destination addresses that the Proxy Client does not want to receive.
    /// The black list filter accepts all destination addresses except those
    /// that have been added to the black list.
    case blacklist = 0x01
}

public class ProxyFilter {
    internal var manager: MeshNetworkManager
    
    // MARK: - Proxy Filter properties
    
    /// List of addresses currently added to the Proxy Filter.
    public internal(set) var addresses: [Address] = []
    /// The active Proxy Filter type.
    ///
    /// By default the Proxy Filter is set to `.whitelist`.
    public internal(set) var type: ProxyFilerType = .whitelist
    
    // MARK: - Implementation
    
    internal init(_ manager: MeshNetworkManager) {
        self.manager = manager
    }
    
    /// Sets the Filter Type on the connected GATT Proxy Node.
    /// The filter will be emptied.
    ///
    /// - parameter type: The new proxy filter type.
    public func setType(_ type: ProxyFilerType) {
        manager.send(SetFilterType(type))
    }
    
    /// Clears the current filter.
    public func clear() {
        manager.send(SetFilterType(type))
    }
    
    /// Adds the given Addresses to the active filter.
    ///
    /// - parameter addresses: The addresses to add to the filter.
    public func add(addresses: [Address]) {
        manager.send(AddAddressesToFilter(addresses))
    }
    
    /// Adds the given Groups to the active filter.
    ///
    /// - parameter groups: The groups to add to the filter.
    public func add(groups: [Group]) {
        let addresses = groups.map { $0.address.address }
        add(addresses: addresses)
    }
    
    /// Removes the given GroAddresses from the active filter.
    ///
    /// - parameter addresses: The addresses to remove from the filter.
    public func remove(addresses: [Address]) {
        manager.send(RemoveAddressesFromFilter(addresses))
    }
    
    /// Removes the given Groups from the active filter.
    ///
    /// - parameter groups: The groups to remove from the filter.
    public func remove(groups: [Group]) {
        let addresses = groups.map { $0.address.address }
        remove(addresses: addresses)
    }
    
}
