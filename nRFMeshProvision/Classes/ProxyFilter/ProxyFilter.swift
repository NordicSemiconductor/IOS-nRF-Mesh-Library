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

public enum ProxyFilerType: UInt8 {
    /// An inclusion list filter has an associated inclusion list, which is
    /// a list of destination addresses that are of interest for the Proxy Client.
    /// The inclusion list filter blocks all messages except those targeting
    /// addresses added to the list.
    case inclusionList = 0x00
    /// An exclusion list filter has an associated exclusion list, which is
    /// a list of destination addresses that the Proxy Client does not want to receive.
    /// The exclusion list filter forwards all messages except those targeting
    /// addresses added to the list.
    case exclusionList = 0x01
}

public protocol ProxyFilterDelegate: AnyObject {
    /// Method called when the Proxy Filter has been updated.
    ///
    /// - parameters:
    ///   - type: The current Proxy Filter type.
    ///   - addresses: The addresses in the filter.
    func proxyFilterUpdated(type: ProxyFilerType, addresses: Set<Address>)
    
    /// This method is called when the connected Proxy device supports
    /// only a single address in the Proxy Filter list.
    ///
    /// The delegate can switch to `.blacklist` filter type at that point
    /// to receive messages sent to other addresses than 0th Element
    /// Unicast Address.
    ///
    /// - parameter maxSize: The maximum Proxy Filter list size.
    func limitedProxyFilterDetected(maxSize: Int)
}

public extension ProxyFilterDelegate {
    
    func limitedProxyFilterDetected(maxSize: Int) {
        // Do nothing.
    }
    
}

public protocol ProxyFilter {
    // MARK: - Proxy Filter properties
    
    /// The delegate to be informed about Proxy Filter changes.
    var delegate: ProxyFilterDelegate? { get set }

    /// List of addresses currently added to the Proxy Filter.
    var addresses: Set<Address> { get }

    /// The active Proxy Filter type.
    ///
    /// According to Bluetooth Mesh Profile 1.0.1, section 6.6,
    /// by default the Proxy Filter is set to `.inclusionList`.
    var type: ProxyFilerType { get }

    /// The connected Proxy Node. This may be `nil` if the connected Node is unknown
    /// to the provisioner, that is if a Node with the proxy Unicast Address was not found
    /// in the local mesh network database. It is also `nil` if no proxy is connected.
    var proxy: Node? { get }

    // MARK: - Proxy Filter functions

    /// Sets the Filter Type on the connected GATT Proxy Node.
    /// The filter will be emptied.
    ///
    /// - parameter type: The new proxy filter type.
    func setType(_ type: ProxyFilerType)

    /// Resets the filter to an empty inclusion list filter.
    func reset()

    /// Clears the current filter.
    func clear()

    /// Adds the given Address to the active filter.
    ///
    /// - parameter address: The address to add to the filter.
    func add(address: Address)

    /// Adds the given Addresses to the active filter.
    ///
    /// - parameter addresses: The addresses to add to the filter.
    func add(addresses: Set<Address>)

    /// Removes the given Address from the active filter.
    ///
    /// - parameter address: The address to remove from the filter.
    func remove(address: Address)

    /// Removes the given Addresses from the active filter.
    ///
    /// - parameter addresses: The addresses to remove from the filter.
    func remove(addresses: Set<Address>)

    /// Adds all the addresses the Provisioner is subscribed to to the
    /// Proxy Filter.
    func setup(for provisioner: Provisioner)

    /// Notifies the Proxy Filter that the connection to GATT Proxy is closed.
    ///
    /// This method will unset the `busy` flag.
    func proxyDidDisconnect()
}

public extension ProxyFilter {
    /// Adds the given Addresses to the active filter.
    ///
    /// - parameter addresses: The addresses to add to the filter.
    func add(addresses: [Address]) {
        add(addresses: Set(addresses))
    }

    /// Adds the given Groups to the active filter.
    ///
    /// - parameter groups: The groups to add to the filter.
    func add(groups: [Group]) {
        let addresses = groups.map { $0.address.address }
        add(addresses: addresses)
    }

    /// Removes the given Addresses from the active filter.
    ///
    /// - parameter addresses: The addresses to remove from the filter.
    func remove(addresses: [Address]) {
        remove(addresses: Set(addresses))
    }

    /// Removes the given Groups from the active filter.
    ///
    /// - parameter groups: The groups to remove from the filter.
    func remove(groups: [Group]) {
        let addresses = groups.map { $0.address.address }
        remove(addresses: addresses)
    }
}

// MARK: - Other

extension ProxyFilerType: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .inclusionList: return "Inclusion List"
        case .exclusionList: return "Exclusion List"
        }
    }
    
}
