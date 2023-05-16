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

class SelectPublicationDestinationsViewController: UITableViewController {
    
    // MARK: - Properties
    
    var node: Node!
    var delegate: DestinationDelegate?
    var selectedApplicationKey: ApplicationKey?
    var selectedDestination: MeshAddress?
    
    /// List of Elements.
    private var compatibleElements: [Element]!
    private var selectedKeyIndexPath: IndexPath?
    private var selectedIndexPath: IndexPath?
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let network = MeshNetworkManager.instance.meshNetwork!
        compatibleElements = network.nodes
            .filter { $0 != node }
            .flatMap { $0.elements }
        
        var index: Int? = nil
        if let key = selectedApplicationKey {
            selectedApplicationKey = nil
            index = network.applicationKeys.firstIndex(of: key)
        } else {
            index = network.applicationKeys.isEmpty ? nil : 0
        }
        if let index = index {
            keySelected(IndexPath(row: index, section: IndexPath.keysSection))
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return IndexPath.numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let network = MeshNetworkManager.instance.meshNetwork!
        if section == IndexPath.keysSection {
            return network.applicationKeys.count + 1 // Add Key
        }
        if section == IndexPath.elementsSection {
            return max(compatibleElements.count, 1)
        }
        if section == IndexPath.groupsSection {
            return network.groups.count + 1 // Add Group
        }
        if section == IndexPath.specialGroupsSection {
            return Group.specialGroups.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case IndexPath.keysSection:
            return "Application Keys"
        case IndexPath.elementsSection:
            return "Elements"
        case IndexPath.groupsSection:
            return "Groups"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case IndexPath.elementsSection:
            return "Note: The list above does not contain elements from the configured node."
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.isElementsSection && compatibleElements.isEmpty {
            return 56
        }
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let network = MeshNetworkManager.instance.meshNetwork!
        
        guard !indexPath.isKeySection || indexPath.row < network.applicationKeys.count else {
            return tableView.dequeueReusableCell(withIdentifier: "addKey", for: indexPath)
        }
        guard !indexPath.isElementsSection || !compatibleElements.isEmpty else {
            return tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath)
        }
        guard !indexPath.isGroupsSection || indexPath.row < network.groups.count else {
            return tableView.dequeueReusableCell(withIdentifier: "addGroup", for: indexPath)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: indexPath.reuseIdentifier, for: indexPath)
        
        if indexPath.isKeySection {
            let applicationKey = network.applicationKeys[indexPath.row]
            cell.textLabel?.text = applicationKey.name
            cell.detailTextLabel?.text = "Bound to \(applicationKey.boundNetworkKey.name)"
            cell.accessoryType = indexPath == selectedKeyIndexPath ? .checkmark : .none
        }
        if indexPath.isElementsSection {
            let element = compatibleElements[indexPath.row]
            if let destination = selectedDestination, destination.address == element.unicastAddress {
                selectedIndexPath = indexPath
                selectedDestination = nil
            }
            cell.textLabel?.text = element.name ?? "Element \(element.index + 1)"
            cell.detailTextLabel?.text = element.parentNode!.name ?? "Unknown Device"
            cell.imageView?.image = #imageLiteral(resourceName: "ic_flag_24pt")
            cell.accessoryType = indexPath == selectedIndexPath ? .checkmark : .none
        }
        if indexPath.isGroupsSection {
            let group = network.groups[indexPath.row]
            if let destination = selectedDestination, destination == group.address {
                selectedIndexPath = indexPath
                selectedDestination = nil
            }
            cell.textLabel?.text = group.name
            cell.imageView?.image = #imageLiteral(resourceName: "ic_group_24pt")
            cell.accessoryType = indexPath == selectedIndexPath ? .checkmark : .none
        }
        if indexPath.isSpecialGroupsSection {
            let group = Group.specialGroups[indexPath.row]
            if let destination = selectedDestination, destination == group.address {
                selectedIndexPath = indexPath
                selectedDestination = nil
            }
            cell.textLabel?.text = group.name
            cell.imageView?.image = #imageLiteral(resourceName: "ic_group_24pt")
            cell.accessoryType = indexPath == selectedIndexPath ? .checkmark : .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !indexPath.isElementsSection || !compatibleElements.isEmpty else {
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let manager = MeshNetworkManager.instance
        guard let network = manager.meshNetwork else {
            return
        }
        
        // Select a new key.
        if indexPath.isKeySection {
            // Was Add Key clicked?
            if indexPath.row == network.applicationKeys.count {
                let index = network.applicationKeys.count + 1
                try! network.add(applicationKey: Data.random128BitKey(), name: "App Key \(index)")
                _ = manager.save()
                tableView.insertRows(at: [indexPath], with: .automatic)
                // Continue to select the new key.
            }
            keySelected(indexPath)
            return
        }
        
        // Add Group clicked.
        if indexPath.isGroupsSection && indexPath.row == network.groups.count {
            let number = network.groups.count + 1
            if let address = network.nextAvailableGroupAddress(),
               let newGroup = try? Group(name: "Group \(number)", address: address) {
                try! network.add(group: newGroup)
                _ = manager.save()
                tableView.insertRows(at: [indexPath], with: .automatic)
            }
            // Continue to select the new group.
        }
        
        var rows: [IndexPath] = []
        if let previousSelection = selectedIndexPath {
            rows.append(previousSelection)
        }
        rows.append(indexPath)
        selectedIndexPath = indexPath
        
        tableView.reloadRows(at: rows, with: .automatic)
        
        destinationSelected(indexPath)
    }

}

private extension SelectPublicationDestinationsViewController {
    
    func keySelected(_ indexPath: IndexPath) {
        guard indexPath != selectedKeyIndexPath else {
            return
        }
        
        var rows: [IndexPath] = []
        if let previousSelection = selectedKeyIndexPath {
            rows.append(previousSelection)
        }
        rows.append(indexPath)
        selectedKeyIndexPath = indexPath
        
        // Refresh the Elements list.
        let network = MeshNetworkManager.instance.meshNetwork!
        let key = network.applicationKeys[indexPath.row]
        delegate?.keySelected(key)
        
        tableView.beginUpdates()
        tableView.reloadRows(at: rows, with: .automatic)
        tableView.reloadSections(.elements, with: .automatic)
        tableView.endUpdates()
    }
    
    func destinationSelected(_ indexPath: IndexPath) {
        let network = MeshNetworkManager.instance.meshNetwork!
        switch indexPath.section {
        case IndexPath.elementsSection:
            let element = compatibleElements[indexPath.row]
            delegate?.destinationSelected(MeshAddress(element.unicastAddress))
        case IndexPath.groupsSection where !network.groups.isEmpty:
            let selectedGroup = network.groups[indexPath.row]
            delegate?.destinationSelected(selectedGroup.address)
        default:
            let selectedGroup = Group.specialGroups[indexPath.row]
            delegate?.destinationSelected(selectedGroup.address)
        }
    }
}

private extension IndexPath {
    static let keysSection          = 0
    static let elementsSection      = 1
    static let groupsSection        = 2
    static let specialGroupsSection = 3
    static let numberOfSections     = IndexPath.specialGroupsSection + 1
    
    var reuseIdentifier: String {
        if isKeySection {
            return "key"
        }
        if isElementsSection {
            return "subtitle"
        }
        return "normal"
    }
    
    var isKeySection: Bool {
        return section == IndexPath.keysSection
    }
    
    var isElementsSection: Bool {
        return section == IndexPath.elementsSection
    }
    
    var isGroupsSection: Bool {
        return section == IndexPath.groupsSection
    }
    
    var isSpecialGroupsSection: Bool {
        return section == IndexPath.specialGroupsSection
    }
}

private extension IndexSet {
    
    static let elements = IndexSet(integer: IndexPath.elementsSection)
    
}
