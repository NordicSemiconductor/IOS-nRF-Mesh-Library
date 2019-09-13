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

public protocol ProxyFilterDelegate: class {
    /// Method called when the Proxy Filter has been updated.
    ///
    /// - parameter type: The current Proxy Filter type.
    /// - parameter addresses: The addresses in the filter.
    func proxyFilterUpdated(type: ProxyFilerType, addresses: Set<Address>)
}

public class ProxyFilter {
    internal var manager: MeshNetworkManager
    
    private var counter = 0
    private var busy = false
    private var buffer: [ProxyConfigurationMessage] = []
    
    private var logger: LoggerDelegate? {
        return manager.logger
    }
    
    // MARK: - Proxy Filter properties
    
    /// The delegate to be informed about Proxy Filter changes.
    public weak var delegate: ProxyFilterDelegate?
    
    /// List of addresses currently added to the Proxy Filter.
    public internal(set) var addresses: Set<Address> = []
    /// The active Proxy Filter type.
    ///
    /// By default the Proxy Filter is set to `.whitelist`.
    public internal(set) var type: ProxyFilerType = .whitelist
    
    // MARK: - Implementation
    
    internal init(_ manager: MeshNetworkManager) {
        self.manager = manager
    }
}

// MARK: - Public API

public extension ProxyFilter {
    
    /// Sets the Filter Type on the connected GATT Proxy Node.
    /// The filter will be emptied.
    ///
    /// - parameter type: The new proxy filter type.
    func setType(_ type: ProxyFilerType) {
        send(SetFilterType(type))
    }
    
    /// Resets the filter to an empty whitelist filter.
    func reset() {
        send(SetFilterType(.whitelist))
    }
    
    /// Clears the current filter.
    func clear() {
        send(SetFilterType(type))
    }
    
    /// Adds the given Address to the active filter.
    ///
    /// - parameter address: The address to add to the filter.
    func add(address: Address) {
        send(AddAddressesToFilter(Set(arrayLiteral: address)))
    }
    
    /// Adds the given Addresses to the active filter.
    ///
    /// - parameter addresses: The addresses to add to the filter.
    func add(addresses: [Address]) {
        send(AddAddressesToFilter(Set(addresses)))
    }
    
    /// Adds the given Addresses to the active filter.
    ///
    /// - parameter addresses: The addresses to add to the filter.
    func add(addresses: Set<Address>) {
        send(AddAddressesToFilter(addresses))
    }
    
    /// Adds the given Groups to the active filter.
    ///
    /// - parameter groups: The groups to add to the filter.
    func add(groups: [Group]) {
        let addresses = groups.map { $0.address.address }
        add(addresses: addresses)
    }
    
    /// Removes the given Address from the active filter.
    ///
    /// - parameter address: The address to remove from the filter.
    func remove(address: Address) {
        send(RemoveAddressesFromFilter(Set(arrayLiteral: address)))
    }
    
    /// Removes the given Addresses from the active filter.
    ///
    /// - parameter addresses: The addresses to remove from the filter.
    func remove(addresses: [Address]) {
        send(RemoveAddressesFromFilter(Set(addresses)))
    }
    
    /// Removes the given Addresses from the active filter.
    ///
    /// - parameter addresses: The addresses to remove from the filter.
    func remove(addresses: Set<Address>) {
        send(RemoveAddressesFromFilter(addresses))
    }
    
    /// Removes the given Groups from the active filter.
    ///
    /// - parameter groups: The groups to remove from the filter.
    func remove(groups: [Group]) {
        let addresses = groups.map { $0.address.address }
        remove(addresses: addresses)
    }
    
    /// Adds all the addresses the Provisioner is subscribed to to the
    /// Proxy Filter.
    func setup(for provisioner: Provisioner) {
        guard let node = provisioner.node else {
            return
        }
        var addresses: Set<Address> = []
        // Add Unicast Addresses of all Elements of the Provisioner's Node.
        addresses.formUnion(node.elements.map({ $0.unicastAddress }))
        // Add all addresses that the Node's Models are subscribed to.
        let models = node.elements.flatMap { $0.models }
        let subscriptions = models.flatMap { $0.subscriptions }
        addresses.formUnion(subscriptions.map({ $0.address.address }))
        // Add All Nodes group address.
        addresses.insert(Address.allNodes)
        // Submit.
        add(addresses: addresses)
    }
    
}

// MARK: - Callbacks

internal extension ProxyFilter {
    
    /// Callback called when a possible change of Proxy Node have been discovered.
    ///
    /// This method is called in two cases: when the first Secure Network
    /// beacon was received (which indicates the first successful connection
    /// to a Proxy since app was started) or when the received Secure Network
    /// beacon contained information about the same Network Key as one
    /// received before. This happens during a reconnection to the same
    /// or a different Proxy on the same subnetwork, but may also happen
    /// in other sircumstances, for example when the IV Update or Key Refresh
    /// Procedure is in progress, or a Network Key was removed and added again.
    ///
    /// This method reloads the Proxy Filter for the local Provisioner,
    /// adding all the addresses the Provisioner is subscribed to, including
    /// its Unicast Addresses and All Nodes address.
    func newProxyDidConnect() {
        logger?.i(.proxy, "New Proxy connected")
        reset()
        if let localProvisioner = manager.meshNetwork?.localProvisioner {
            setup(for: localProvisioner)
        }
    }
    
    /// Callback called when a Proxy Configuration Message has been sent.
    ///
    /// This method refreshes the local type and list of addresses.
    ///
    /// - parameter message: The message sent.
    func managerDidDeliverMessage(_ message: ProxyConfigurationMessage) {
        switch message {
        case let request as AddAddressesToFilter:
            addresses.formUnion(request.addresses)
        case let request as RemoveAddressesFromFilter:
            addresses.subtract(request.addresses)
        case let request as SetFilterType:
            type = request.filterType
            addresses.removeAll()
        default:
            // Ignore.
            break
        }
    }
    
    /// Callback called when the manager failed to send the Proxy
    /// Configuration Message.
    ///
    /// This method clears the local filter and sets it back to `.whitelist`.
    /// All the messages waiting to be sent are cancelled.
    ///
    /// - parameter message: The message that has not been sent.
    /// - parameter error: The error received.
    func managerFailedToDeliverMessage(_ message: ProxyConfigurationMessage, error: Error) {
        type = .whitelist
        addresses.removeAll()
        buffer.removeAll()
        busy = false
    }
    
    /// Handler for the received Proxy Configuration Messages.
    ///
    /// This method notifies the delegate about changes in the Proxy Filter.
    ///
    /// If a mismatchis detected between the local list of services and
    /// the list size received, the method will try to clear the remote
    /// filter and send all the addresses again.
    ///
    /// - parameter message: The message received.
    func handle(_ message: ProxyConfigurationMessage) {
        switch message {
        case let status as FilterStatus:
            // Handle buffered messages.
            guard buffer.isEmpty else {
                let message = buffer.removeFirst()
                try? manager.send(message)
                return
            }
            busy = false
            
            // Ensure the current information about the filter is up to date.
            guard type == status.filterType && addresses.count == status.listSize else {
                // The counter is used to prevent from refreshing the
                // filter in a loop when the Proxy Server responds with
                // an unexpected list size.
                guard counter == 0 else {
                    logger?.e(.proxy, "Proxy Filter lost track of devices")
                    counter = 0
                    return
                }
                counter += 1
                
                logger?.w(.proxy, "Refreshing Proxy Filter...")
                let addresses = self.addresses
                clear()
                add(addresses: addresses)
                return
            }
            counter = 0
            
            // And notify the app.
            delegate?.proxyFilterUpdated(type: type, addresses: addresses)
        default:
            // Ignore.
            break
        }
    }
    
}

// MARK: - Helper methods

private extension ProxyFilter {
    
    /// Sends the given message to the Proxy Server. If a previous message
    /// is still waiting for status, this will buffer the message and send
    /// it after the status is received.
    ///
    /// - parameter message: The message to be sent.
    func send(_ message: ProxyConfigurationMessage) {
        guard !busy else {
            buffer.append(message)
            return
        }
        busy = true
        do {
            try manager.send(message)
        } catch {
            busy = false
        }
    }
    
}

// MARK: - Other

extension ProxyFilerType: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .whitelist: return "Whitelist"
        case .blacklist: return "Blacklist"
        }
    }
    
}
