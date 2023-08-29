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

import UIKit
import nRFMeshProvision

class ProxyViewController: ProgressViewController, Editable {
    
    // MARK: - Outlets and Actions
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    // MARK: - Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MeshNetworkManager.bearer.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
        
        MeshNetworkManager.instance.proxyFilter.delegate = self
        addButton.isEnabled = MeshNetworkManager.bearer.isOpen
        
        if MeshNetworkManager.instance.proxyFilter.addresses.isEmpty == false {
            hideEmptyView()
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "selectProxy" {
            return !MeshNetworkManager.bearer.isConnectionModeAutomatic
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navigationController = segue.destination as? UINavigationController
        navigationController?.presentationController?.delegate = self
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case IndexPath.statusSection:
            return 3
        case IndexPath.proxyTypeSection:
            return 1
        default:
            return MeshNetworkManager.instance.proxyFilter.addresses.count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == IndexPath.proxyTypeSection {
            return "Proxy Filter"
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == IndexPath.proxyTypeSection {
            if MeshNetworkManager.instance.proxyFilter.type == .rejectList {
                return "The reject list filter accepts all destination addresses except those that have been added to the list."
            } else {
                return "The accept list filter blocks all destination addresses except those that have been added to the list."
            }
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let manager = MeshNetworkManager.instance
        let proxyFilter = manager.proxyFilter
        
        if indexPath == .mode {
            let cell = tableView.dequeueReusableCell(withIdentifier: "mode", for: indexPath) as! ConnectionModeCell
            cell.delegate = self
            return cell
        }
        if indexPath == .status {
            let cell = tableView.dequeueReusableCell(withIdentifier: "status", for: indexPath)
            let bearer = MeshNetworkManager.bearer!
            cell.detailTextLabel?.text = bearer.isOpen ?
                "\(proxyFilter.proxy?.name ?? bearer.name ?? "Unknown device")" :
                bearer.isConnectionModeAutomatic ? "Connecting..." : "Not selected"
            cell.accessoryType = bearer.isConnectionModeAutomatic ? .none : .disclosureIndicator
            cell.selectionStyle = bearer.isConnectionModeAutomatic ? .none : .default
            return cell
        }
        if indexPath == .action {
            let cell = tableView.dequeueReusableCell(withIdentifier: "disconnect", for: indexPath) as! DisconnectCell
            let bearer = MeshNetworkManager.bearer!
            cell.disconnectButton.isEnabled = bearer.isOpen &&
                                             !bearer.isConnectionModeAutomatic
            return cell
        }
        if indexPath == .control {
            let cell = tableView.dequeueReusableCell(withIdentifier: "type", for: indexPath) as! FilterTypeCell
            cell.delegate = self
            cell.type = proxyFilter.type
            cell.filterTypeControl.isEnabled = MeshNetworkManager.bearer.isOpen
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "subtitle", for: indexPath) as! AddressCell
        let addresses = proxyFilter.addresses.sorted()
        guard addresses.count > indexPath.row else {
            cell.address = .unassignedAddress
            return cell
        }
        cell.address = addresses.sorted()[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == IndexPath.addressesSection
    }
    
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        let proxyFilter = MeshNetworkManager.instance.proxyFilter
        let address = proxyFilter.addresses.sorted()[indexPath.row]
        deleteAddress(address)
    }

}

extension ProxyViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        MeshNetworkManager.instance.proxyFilter.delegate = self
        tableView.reloadSections(.addresses, with: .automatic)
    }
    
}

extension ProxyViewController: BearerDelegate {
    
    func bearerDidOpen(_ bearer: Bearer) {
        addButton.isEnabled = true
        tableView.reloadRows(at: [.status, .action, .control], with: .automatic)
    }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        addButton.isEnabled = false
        // Make sure the ProxyFilter is not busy.
        MeshNetworkManager.instance.proxyFilter.proxyDidDisconnect()
        // The bearer has closed. Attempt to send a message
        // will fail, but the Proxy Filter will receive .bearerClosed
        // error, upon which it will clear the filter list and notify
        // the delegate.
        MeshNetworkManager.instance.proxyFilter.clear()
    }
    
}

extension ProxyViewController: ConnectionModeDelegate {
    
    func connectionModeDidChange(automatic: Bool) {
        tableView.reloadRows(at: [.status, .action], with: .automatic)
    }
    
}

extension ProxyViewController: ProxyFilterTypeDelegate {
    
    func filterTypeDidChange(_ type: ProxyFilerType) {
        let footer = tableView.footerView(forSection: 0)?.textLabel
        switch type {
        case .exclusionList:
            footer?.text = "The reject list filter accepts all destination addresses except those that have been added to the list."
        default:
            footer?.text = "The accept list filter blocks all destination addresses except those that have been added to the list."
        }
        footer?.sizeToFit()
        start("Setting proxy filter...") {
            MeshNetworkManager.instance.proxyFilter.setType(type)
        }
    }
    
}

extension ProxyViewController: ProxyFilterDelegate {
    
    func proxyFilterUpdated(type: ProxyFilerType, addresses: Set<Address>) {
        done {
            self.tableView.reloadData()
        }
    }
    
    func proxyFilterUpdateAcknowledged(type: ProxyFilerType, listSize: UInt16) {
        // TODO: dismiss here?
    }
    
}

private extension ProxyViewController {
    
    /// Deletes the given address from Proxy Filter.
    ///
    /// - parameter address: The address to delete.
    func deleteAddress(_ address: Address) {
        let proxyFilter = MeshNetworkManager.instance.proxyFilter
        guard proxyFilter.addresses.contains(address) else {
            return
        }
        start("Deleting address...") {
            proxyFilter.remove(address: address)
        }
    }
    
}

private extension IndexPath {
    static let statusSection = 0
    static let proxyTypeSection = 1
    static let addressesSection = 2
    
    static let mode    = IndexPath(row: 0, section: IndexPath.statusSection)
    static let status  = IndexPath(row: 1, section: IndexPath.statusSection)
    static let action  = IndexPath(row: 2, section: IndexPath.statusSection)
    static let control = IndexPath(row: 0, section: IndexPath.proxyTypeSection)
}

private extension IndexSet {
    static let details   = IndexSet(integer: IndexPath.statusSection)
    static let addresses = IndexSet(integer: IndexPath.addressesSection)
}
