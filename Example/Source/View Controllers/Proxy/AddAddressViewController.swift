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

class AddAddressViewController: ProgressViewController {
    
    // MARK: - Outlets and Actions
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        if let customCell = tableView.cellForRow(at: IndexPath.customAddress) as? CustomAddressCell {
            // This will trigger `customAddressDidChange(_:Address)` if the
            // custom address was being edited.
            customCell.addressField.resignFirstResponder()
        }
        if let customAddress = customAddress {
            selectedAddresses.insert(customAddress)
        }
        guard !selectedAddresses.isEmpty else {
            dismiss(animated: true)
            return
        }
        addAddress(selectedAddresses)
    }
    
    // MARK: - Properties
    
    private var elements: [Element]!
    private var groups: [Group]!
    private var specialGroups: [Address]!
    
    private var customAddressSelected: Bool = false
    private var customAddress: Address?
    private var selectedAddresses: Set<Address> = []
    
    // MARK: - Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MeshNetworkManager.instance.proxyFilter.delegate = self
        
        let network = MeshNetworkManager.instance.meshNetwork!
        let proxyFilter = MeshNetworkManager.instance.proxyFilter
        
        elements = network.nodes.flatMap {
            $0.elements.filter({ !proxyFilter.addresses.contains($0.unicastAddress) })
        }.sorted(by: { $0.unicastAddress < $1.unicastAddress })
        groups = network.groups.filter {
            !proxyFilter.addresses.contains($0.address.address)
        }.sorted(by: { $0.name < $1.name })
        specialGroups = [Address.allProxies, Address.allFriends, Address.allRelays, Address.allNodes].filter {
            !proxyFilter.addresses.contains($0)
        }
        doneButton.isEnabled = false
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return specialGroups.isEmpty ? 3 : 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return max(1, elements.count)
        case 2: return max(1, groups.count)
        case 3: return max(1, specialGroups.count)
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: return "Elements"
        case 2: return "Groups"
        default: return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.isCustomSection {
            let cell = tableView.dequeueReusableCell(withIdentifier: "custom", for: indexPath) as! CustomAddressCell
            cell.accessoryType = customAddressSelected ? .checkmark : .none
            cell.delegate = self
            return cell
        }
        if indexPath.isElementsSection {
            guard elements.count > indexPath.row else {
                return tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath)
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "subtitle", for: indexPath) as! AddressCell
            cell.address = elements[indexPath.row].unicastAddress
            cell.accessoryType = selectedAddresses.contains(cell.address) ? .checkmark : .none
            return cell
        }
        if indexPath.isGroupsSection {
            guard groups.count > indexPath.row else {
                return tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath)
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "subtitle", for: indexPath) as! AddressCell
            cell.address = groups[indexPath.row].address.address
            cell.accessoryType = selectedAddresses.contains(cell.address) ? .checkmark : .none
            return cell
        }
        if indexPath.isSpecialGroupSection {
            guard specialGroups.count > indexPath.row else {
                return tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath)
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "subtitle", for: indexPath) as! AddressCell
            cell.address = specialGroups[indexPath.row]
            cell.accessoryType = selectedAddresses.contains(cell.address) ? .checkmark : .none
            return cell
        }
        fatalError("Invalid IndexPath")
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let customCell = tableView.cellForRow(at: IndexPath.customAddress) as? CustomAddressCell {
            customCell.addressField.resignFirstResponder()
        }
        
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        
        if indexPath.section == IndexPath.customAddressSection {
            customAddressSelected = !customAddressSelected
            cell.accessoryType = customAddressSelected ? .checkmark : .none
            doneButton.isEnabled = !selectedAddresses.isEmpty || customAddressSelected
            return
        }
        
        guard let addressCell = cell as? AddressCell else {
            return
        }
        
        if selectedAddresses.contains(addressCell.address) {
            selectedAddresses.remove(addressCell.address)
            cell.accessoryType = .none
        } else {
            selectedAddresses.insert(addressCell.address)
            cell.accessoryType = .checkmark
        }
        doneButton.isEnabled = !selectedAddresses.isEmpty || customAddressSelected
    }
    
}

private extension AddAddressViewController {
    
    func addAddress(_ addresses: Set<Address>) {
        start("Adding addresses...") {
            MeshNetworkManager.instance.proxyFilter.add(addresses: addresses)
        }
    }
    
}

extension AddAddressViewController: ProxyFilterDelegate {
    
    func proxyFilterUpdated(type: ProxyFilerType, addresses: Set<Address>) {
        done {
            self.dismiss(animated: true)
        }
    }
    
    func proxyFilterUpdateAcknowledged(type: ProxyFilerType, listSize: UInt16) {
        // TODO: dismiss here?
    }
    
}

extension AddAddressViewController: CustomAddressDelegate {
    
    func customAddressEditingDidBegin() {
        customAddressSelected = true
        doneButton.isEnabled = true
    }
    
    func customAddressDidChange(_ address: Address?) {
        customAddress = address
    }    
    
}

private extension IndexPath {
    static let customAddressSection = 0
    static let elementsSection = 1
    static let groupsSection = 2
    static let specialGroupsSection = 3
    
    static let customAddress = IndexPath(row: 0, section: IndexPath.customAddressSection)
    
    var isCustomSection: Bool {
        return section == IndexPath.customAddressSection
    }
    var isElementsSection: Bool {
        return section == IndexPath.elementsSection
    }
    var isGroupsSection: Bool {
        return section == IndexPath.groupsSection
    }
    var isSpecialGroupSection: Bool {
        return section == IndexPath.specialGroupsSection
    }
}
