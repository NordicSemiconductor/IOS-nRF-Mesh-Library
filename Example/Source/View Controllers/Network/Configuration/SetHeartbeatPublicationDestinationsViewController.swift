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

protocol HeartbeatDestinationDelegate {
    func keySelected(_ networkKey: NetworkKey)
    func destinationSelected(_ address: Address)
}

class SetHeartbeatPublicationDestinationsViewController: UITableViewController {
    
    // MARK: - Properties
    
    var target: Node!
    var delegate: HeartbeatDestinationDelegate?
    var selectedNetworkKey: NetworkKey?
    var selectedDestination: Address?
    
    /// List of all Nodes, except the target one.
    private var nodes: [Node]!
    private var groups: [Group]!
    private var selectedKeyIndexPath: IndexPath?
    private var selectedIndexPath: IndexPath?
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let network = MeshNetworkManager.instance.meshNetwork!
        // Exclude the current Node.
        nodes = network.nodes.filter { $0.uuid != target.uuid }
        // Virtual Groups may not be set as Heartbeat destination.
        // They will be shown as disabled.
        // Sort the groups, so the Virtual Groups are at the end.
        groups = network.groups.sorted { $1.address.address.isVirtual }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return IndexPath.numberOfSections(for: groups)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == IndexPath.keysSection {
            return target.networkKeys.count
        }
        if section == IndexPath.nodesSection {
            return max(nodes.count, 1)
        }
        if section == IndexPath.groupsSection {
            return groups.count + 1 // Add Group
        }
        if section == IndexPath.specialGroupsSection {
            return Group.specialGroups.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case IndexPath.keysSection:
            return "Network Keys"
        case IndexPath.nodesSection:
            return "Destination"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == IndexPath.groupsSection && groups.contains(where: { $0.address.address.isVirtual }) {
            return "Note: Heartbeat messages cannot be sent to Virtual Groups."
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard !indexPath.isNodeSection || nodes.count > 0 else {
            return tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath)
        }
        guard !indexPath.isGroupsSection || indexPath.row < groups.count else {
            return tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: indexPath.reuseIdentifier, for: indexPath)
        
        if indexPath.isKeySection {
            let networkKey = target.networkKeys[indexPath.row]
            if selectedNetworkKey?.index == networkKey.index {
                selectedKeyIndexPath = indexPath
                selectedNetworkKey = nil
            }
            cell.textLabel?.text = networkKey.name
            cell.accessoryType = indexPath == selectedKeyIndexPath ? .checkmark : .none
            cell.isEnabled = true
        }
        if indexPath.isNodeSection {
            let node = nodes[indexPath.row]
            if let destination = selectedDestination, destination == node.primaryUnicastAddress {
                selectedIndexPath = indexPath
                selectedDestination = nil
            }
            cell.textLabel?.text = node.name ?? "Unknown Device"
            cell.imageView?.image = #imageLiteral(resourceName: "ic_flag_24pt")
            cell.accessoryType = indexPath == selectedIndexPath ? .checkmark : .none
            cell.isEnabled = true
        }
        if indexPath.isGroupsSection {
            let group = groups[indexPath.row]
            if let destination = selectedDestination, destination == group.address.address {
                selectedIndexPath = indexPath
                selectedDestination = nil
            }
            cell.textLabel?.text = group.name
            cell.imageView?.image = #imageLiteral(resourceName: "ic_group_24pt")
            cell.accessoryType = indexPath == selectedIndexPath ? .checkmark : .none
            cell.isEnabled = !group.address.address.isVirtual
        }
        if indexPath.isSpecialGroupsSection {
            let group = Group.specialGroups[indexPath.row]
            if let destination = selectedDestination, destination == group.address.address {
                selectedIndexPath = indexPath
                selectedDestination = nil
            }
            cell.textLabel?.text = group.name
            cell.imageView?.image = #imageLiteral(resourceName: "ic_group_24pt")
            cell.accessoryType = indexPath == selectedIndexPath ? .checkmark : .none
            cell.isEnabled = true
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !indexPath.isNodeSection || !nodes.isEmpty else {
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Add Group clicked.
        if indexPath.isGroupsSection && indexPath.row == groups.count {
            let tabBarController = presentingViewController as? RootTabBarController
            dismiss(animated: true) {
                tabBarController?.presentGroups()
            }
            return
        }
        
        if indexPath.isKeySection {
            keySelected(indexPath)
        } else {
            destinationSelected(indexPath)
        }
    }

}

private extension SetHeartbeatPublicationDestinationsViewController {
    
    func keySelected(_ indexPath: IndexPath) {
        // Refresh previously selected and the new rows.
        var rows: [IndexPath] = []
        if let previousSelection = selectedKeyIndexPath {
            rows.append(previousSelection)
        }
        selectedKeyIndexPath = indexPath
        rows.append(indexPath)
        tableView.reloadRows(at: rows, with: .automatic)
        
        // Call delegate.
        let network = MeshNetworkManager.instance.meshNetwork!
        delegate?.keySelected(network.networkKeys[indexPath.row])
    }
    
    func destinationSelected(_ indexPath: IndexPath) {
        // Refresh previously selected and the new rows.
        var rows: [IndexPath] = []
        if let previousSelection = selectedIndexPath {
            rows.append(previousSelection)
        }
        selectedIndexPath = indexPath
        rows.append(indexPath)
        tableView.reloadRows(at: rows, with: .automatic)
        
        // Call delegate.
        switch indexPath.section {
        case IndexPath.nodesSection:
            let node = nodes[indexPath.row]
            delegate?.destinationSelected(node.primaryUnicastAddress)
        case IndexPath.groupsSection where !groups.isEmpty:
            let selectedGroup = groups[indexPath.row]
            delegate?.destinationSelected(selectedGroup.address.address)
        default:
            let selectedGroup = Group.specialGroups[indexPath.row]
            delegate?.destinationSelected(selectedGroup.address.address)
        }
    }
    
}

private extension IndexPath {
    static let keysSection          = 0
    static let nodesSection         = 1
    static let groupsSection        = 2
    static let specialGroupsSection = 3
    static func numberOfSections(for groups: [Group]) -> Int {
        return groups.isEmpty ?
            IndexPath.groupsSection + 1 :
            IndexPath.specialGroupsSection + 1
    }
    
    var reuseIdentifier: String {
        if isKeySection {
            return "key"
        }
        return "normal"
    }
    
    var isKeySection: Bool {
        return section == IndexPath.keysSection
    }
    
    var isNodeSection: Bool {
        return section == IndexPath.nodesSection
    }
    
    var isGroupsSection: Bool {
        return section == IndexPath.groupsSection
    }
    
    var isSpecialGroupsSection: Bool {
        return section == IndexPath.specialGroupsSection
    }
}

private extension IndexSet {
    
    static let nodes = IndexSet(integer: IndexPath.nodesSection)
    
}
