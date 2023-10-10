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

/// A type of the Proxy Filter.
public enum ProxyFilerType {
    /// An accept list filter has an associated accept list containing
    /// destination addresses that are of interest for the Proxy Client.
    ///
    /// The accept list filter blocks all messages except those targeting
    /// addresses added to the list.
    case acceptList
    /// An reject list filter has an associated reject list containing
    /// destination addresses that are NOT of the Proxy Client interest.
    ///
    /// The reject list filter forwards all messages except those targeting
    /// addresses added to the list.
    case rejectList
    
    @available(*, deprecated, renamed: "acceptList")
    case inclusionList
    @available(*, deprecated, renamed: "rejectList")
    case exclusionList
    
    internal static func from(rawValue: UInt8) -> ProxyFilerType? {
        switch rawValue {
        case 0x00: return .acceptList
        case 0x01: return .rejectList
        default: return nil
        }
    }
    
    internal var rawValue: UInt8 {
        switch self {
        case .acceptList, .inclusionList: return 0x00
        case .rejectList, .exclusionList: return 0x01
        }
    }
}

/// The delegate that will be notified about changes of the Proxy Filter.
public protocol ProxyFilterDelegate: AnyObject {
    /// Method called when the Proxy Filter has been sent to proxy.
    ///
    /// - parameters:
    ///   - type: The current Proxy Filter type.
    ///   - addresses: The addresses in the filter.
    func proxyFilterUpdated(type: ProxyFilerType, addresses: Set<Address>)

    /// Method called when the Proxy Filter has been acknowledged by proxy.
    ///
    /// - parameters:
    ///   - type: The current Proxy Filter type.
    ///   - listSize: The addresses list's size in the filter
    func proxyFilterUpdateAcknowledged(type: ProxyFilerType, listSize: UInt16)
    
    /// This method is called when the connected Proxy device supports
    /// only a single address in the Proxy Filter list.
    ///
    /// The delegate can switch to `.exclusionList` filter type at that point
    /// to receive messages sent to addresses other than those that were
    /// added successfully.
    ///
    /// - parameter maxSize: The maximum Proxy Filter list size.
    func limitedProxyFilterDetected(maxSize: Int)
}

public extension ProxyFilterDelegate {
    
    func limitedProxyFilterDetected(maxSize: Int) {
        // Do nothing.
    }
    
}

/// An enumeration for different initial configurations of the Proxy Filter.
public enum ProxyFilterSetup {
    /// In automatic Proxy Filter setup the filter will be set to
    /// ``ProxyFilerType/acceptList`` with Unicast Addresses of all
    /// local Elements, all Group Addresses with at least one local Model
    /// subscribed and the All Nodes (0xFFFF) address.
    ///
    /// This is the default configuration.
    case automatic
    
    /// The Proxy Filter on each connected Proxy Node will be set to
    /// ``ProxyFilerType/acceptList`` with given set of addresses.
    case acceptList(addresses: Set<Address>)
    
    /// The Proxy Filter on each connected Proxy Node will be set to
    /// ``ProxyFilerType/rejectList`` with given set of addresses.
    case rejectList(addresses: Set<Address>)
    
    /// The Proxy Filter on each connected Proxy Node will be set to
    /// ``ProxyFilerType/acceptList`` with given set of addresses.
    @available(*, deprecated, renamed: "acceptList")
    case inclusionList(addresses: Set<Address>)
    
    /// The Proxy Filter on each connected Proxy Node will be set to
    /// ``ProxyFilerType/rejectList`` with given set of addresses.
    @available(*, deprecated, renamed: "rejectList")
    case exclusionList(addresses: Set<Address>)
}

/// The Proxy Filter class allows modification of the proxy filter on the
/// connected Proxy Node.
///
/// Initially, upon connection to a Proxy Node, the manager will automatically
/// subscribe to the Unicast Addresses of all local Elements and all Groups
/// that at least one local Model is subscribed to, including address 0xFFFF
/// (All Nodes).
///
/// - important: When a local Model gets subscribed to a new Group, or is
///              unsubscribed from a Group that no other local Model is
///              subscribed to, the proxy filter needs to be modified manually
///              by calling proper ``ProxyFilter/add(address:)``
///              or ``ProxyFilter/remove(address:)`` method.
public class ProxyFilter {
    /// The owner manager instance.
    ///
    /// The reference is weak to avoid cyclic reference.
    internal weak var manager: MeshNetworkManager?
    
    /// A mutex object for internal synchronization.
    private let mutex = DispatchQueue(label: "ProxyFilterMutex")
    /// A queue to call delegate methods on.
    ///
    /// The value is set in the ``MeshNetworkManager`` initializer.
    private let delegateQueue: DispatchQueue
    /// The counter is used to prevent from refreshing the filter in a loop when the Proxy Server
    /// responds with an unexpected list size.
    private var counter = 0
    /// The flag is set to `true` when a request hsa been sent to the connected proxy.
    /// It is cleared when a response was received, or in case of an error.
    private var busy = false
    /// A queue of proxy configuration messages enqueued to be sent.
    private var buffer: [ProxyConfigurationMessage] = []
    /// A shortcut to the manager's logger.
    private var logger: LoggerDelegate? {
        return manager?.logger
    }
    
    // MARK: - Proxy Filter properties
    
    /// The delegate to be informed about Proxy Filter changes.
    public weak var delegate: ProxyFilterDelegate?
    
    /// Initial configuration of the Proxy Filter for each new
    /// connection to a Proxy Node.
    public var initialState: ProxyFilterSetup = .automatic
    
    /// List of addresses currently added to the Proxy Filter.
    public private(set) var addresses: Set<Address> = []
    
    /// The active Proxy Filter type.
    ///
    /// By default the Proxy Filter is set to ``ProxyFilerType/acceptList``.
    public private(set) var type: ProxyFilerType = .acceptList
    
    /// The connected Proxy Node. This may be `nil` if the connected Node is unknown
    /// to the provisioner, that is if a Node with the proxy Unicast Address was not found
    /// in the local mesh network database. It is also `nil` if no proxy is connected.
    public private(set) var proxy: Node?
    
    // MARK: - Implementation
    
    internal init(_ delegateQueue: DispatchQueue) {
        self.delegateQueue = delegateQueue
    }
    
    internal func use(with manager: MeshNetworkManager) {
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
    
    /// Resets the filter to an empty accept list filter.
    func reset() {
        send(SetFilterType(.acceptList))
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
        add(addresses: Set(addresses))
    }
    
    /// Adds the given Addresses to the active filter.
    ///
    /// - parameter addresses: The addresses to add to the filter.
    func add(addresses: Set<Address>) {
        // Proxy message must fit in a single Network PDU,
        // therefore may contain maximum 5 addresses.
        for set in addresses.chunked(maxSize: 5) {
            send(AddAddressesToFilter(set))
        }
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
        remove(addresses: Set(addresses))
    }
    
    /// Removes the given Addresses from the active filter.
    ///
    /// - parameter addresses: The addresses to remove from the filter.
    func remove(addresses: Set<Address>) {
        // Proxy message must fit in a single Network PDU,
        // therefore may contain maximum 5 addresses.
        for set in addresses.chunked(maxSize: 5) {
            send(RemoveAddressesFromFilter(set))
        }
    }
    
    /// Removes the given Groups from the active filter.
    ///
    /// - parameter groups: The groups to remove from the filter.
    func remove(groups: [Group]) {
        let addresses = groups.map { $0.address.address }
        remove(addresses: addresses)
    }
    
    /// Adds all the addresses the Provisioner is subscribed to the
    /// Proxy Filter.
    func setup(for provisioner: Provisioner) {
        guard let node = provisioner.node else {
            return
        }
        // Make sure the Filter Type is set to accept list.
        if type == .rejectList {
            setType(.acceptList)
        }
        var addresses: Set<Address> = []
        // Add Unicast Addresses of all Elements of the Provisioner's Node.
        addresses.formUnion(node.elements.map({ $0.unicastAddress }))
        // Add all addresses that the Node's Models are subscribed to.
        let models = node.elements.flatMap { $0.models }
        let subscriptions = models.flatMap { $0.subscriptions }
        addresses.formUnion(subscriptions.map({ $0.address.address }))
        // Add All Nodes group address.
        addresses.insert(.allNodes)
        // Submit.
        add(addresses: addresses)
    }
    
    /// Notifies the Proxy Filter that the connection to GATT Proxy is closed.
    ///
    /// This method will unset the `busy` flag.
    func proxyDidDisconnect() {
        mutex.sync {
            busy = false
            proxy = nil
        }
    }
    
}

// MARK: - Callbacks

internal protocol ProxyFilterEventHandler: AnyObject {
        
    /// Clears the current Proxy Filter state.
    func newNetworkCreated()
    
    /// Callback called when a possible change of Proxy Node have been discovered.
    ///
    /// This method is called in two cases: when the first Secure Network
    /// beacon was received (which indicates the first successful connection
    /// to a Proxy since app was started) or when the received Secure Network
    /// beacon contained information about the same Network Key as one
    /// received before. This happens during a reconnection to the same
    /// or a different Proxy on the same subnetwork, but may also happen
    /// in other Circumstances, for example when the IV Update or Key Refresh
    /// Procedure is in progress, or a Network Key was removed and added again.
    ///
    /// This method reloads the Proxy Filter for the local Provisioner,
    /// adding all the addresses the Provisioner is subscribed to, including
    /// its Unicast Addresses and All Nodes address.
    func newProxyDidConnect()
    
    /// Callback called when a Proxy Configuration Message has been sent.
    ///
    /// This method refreshes the local type and list of addresses.
    ///
    /// - parameter message: The message sent.
    func managerDidDeliverMessage(_ message: ProxyConfigurationMessage)
    
    /// Callback called when the manager failed to send the Proxy
    /// Configuration Message.
    ///
    /// This method clears the local filter and sets it back to ``ProxyFilerType/acceptList``.
    /// All the messages waiting to be sent are cancelled.
    ///
    /// - parameters:
    ///   - message: The message that has not been sent.
    ///   - error: The error received.
    func managerFailedToDeliverMessage(_ message: ProxyConfigurationMessage, error: Error)
    
    /// Handler for the received Proxy Configuration Messages.
    ///
    /// This method notifies the delegate about changes in the Proxy Filter.
    ///
    /// If a mismatch is detected between the local list of services and
    /// the list size received, the method will try to clear the remote
    /// filter and send all the addresses again.
    ///
    /// - parameters:
    ///   - message: The message received.
    ///   - proxy: The connected Proxy Node, or `nil` if the Node is unknown.
    func handle(_ message: ProxyConfigurationMessage, sentFrom proxy: Node?)
}

extension ProxyFilter: ProxyFilterEventHandler {
    
    func newNetworkCreated() {
        type = .acceptList
        addresses.removeAll()
        buffer.removeAll()
        busy = false
        counter = 0
        proxy = nil
    }
    
    func newProxyDidConnect() {
        guard let manager = manager else { return }
        
        newNetworkCreated()
        logger?.i(.proxy, "New Proxy connected")
        if let localProvisioner = manager.meshNetwork?.localProvisioner {
            switch initialState {
            case .automatic:
                setup(for: localProvisioner)
            case .rejectList(addresses: let addresses),
                 .exclusionList(addresses: let addresses):
                setType(.rejectList)
                fallthrough
            case .acceptList(addresses: let addresses),
                 .inclusionList(addresses: let addresses):
                add(addresses: addresses)
            }
        }
    }
    
    func managerDidDeliverMessage(_ message: ProxyConfigurationMessage) {
        mutex.sync {
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
        // And notify the app.
        delegateQueue.async {
            self.delegate?.proxyFilterUpdated(type: self.type, addresses: self.addresses)
        }
    }
    
    func managerFailedToDeliverMessage(_ message: ProxyConfigurationMessage, error: Error) {
        mutex.sync {
            type = .acceptList
            addresses.removeAll()
            buffer.removeAll()
            busy = false
        }
        if case BearerError.bearerClosed = error {
            proxy = nil
        }
        // And notify the app.
        delegateQueue.async {
            self.delegate?.proxyFilterUpdated(type: self.type, addresses: self.addresses)
        }
    }
    
    func handle(_ message: ProxyConfigurationMessage, sentFrom proxy: Node?) {
        guard let manager = manager else { return }
        
        switch message {
        case let status as FilterStatus:
            self.proxy = proxy
            // Handle buffered messages.
            if let nextMessage = mutex.sync(execute: {
                                     buffer.isEmpty ? nil : buffer.removeFirst()
                                 }) {
                try? manager.send(nextMessage)
                return
            }
            mutex.sync {
                busy = false
            }
            
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
                
                // Some devices support just a single address in Proxy Filter.
                // After adding 2+ devices they will reply with list size = 1.
                // In that case we could either switch to exclusion list type of filter
                // to get all the traffic, or add only 1 address. By default, this
                // library will add the 0th Element's Unicast Address to allow
                // configuration, as this is the most common use case. If you need
                // to receive messages sent to group addresses or other Elements,
                // switch to exclusion list filter.
                if status.listSize == 1 {
                    logger?.w(.proxy, "Limited Proxy Filter detected.")
                    reset()
                    if let address = manager.meshNetwork?.localProvisioner?.primaryUnicastAddress {
                        mutex.sync {
                            addresses = [address]
                        }
                        add(addresses: addresses)
                    }
                    delegateQueue.async {
                        self.delegate?.limitedProxyFilterDetected(maxSize: 1)
                    }
                } else {
                    logger?.w(.proxy, "Refreshing Proxy Filter...")
                    let addresses = self.addresses // reset() will erase addresses, store it.
                    reset()
                    add(addresses: addresses)
                }
                return
            }
            counter = 0
            delegateQueue.async { [delegate] in
                delegate?.proxyFilterUpdateAcknowledged(type: status.filterType, listSize: status.listSize)
            }
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
        guard let manager = manager else { return }
        
        let wasBusy = mutex.sync { return busy }
        guard !wasBusy else {
            mutex.sync {
                buffer.append(message)
            }
            return
        }
        mutex.sync {
            busy = true
        }
        
        do {
            try manager.send(message)
        } catch {
            mutex.sync {
                busy = false
            }
        }
    }
    
}

// MARK: - Other

extension ProxyFilerType: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .acceptList, .inclusionList: return "Accept List"
        case .rejectList, .exclusionList: return "Reject List"
        }
    }
    
}

extension Set {
    
    func chunked(maxSize: Int) -> [Set<Element>] {
        var result: [Set<Element>] = []
        var current: Set<Element> = []
        for element in self {
            if current.count == maxSize {
                result.append(current)
                current = []
            }
            current.insert(element)
        }
        result.append(current)
        return result
    }
    
}
