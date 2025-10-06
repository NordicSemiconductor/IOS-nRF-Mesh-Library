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
import NordicMesh

protocol DestinationDelegate {
    func keySelected(_ applicationKey: ApplicationKey)
    func destinationSelected(_ address: MeshAddress)
    func destinationCleared()
}

class SetPublicationDestinationsViewController: UITableViewController {
    
    // MARK: - Properties
    
    var model: Model!
    var delegate: DestinationDelegate?
    var selectedApplicationKey: ApplicationKey?
    var selectedDestination: MeshAddress?
    
    private var unicastTargets: [(node: Node, elements: [Element])]!
    private var groups: [Group]!
    private var selectedKeyIndexPath: IndexPath?
    
    private var expandedNodes = Set<Node>()
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let network = MeshNetworkManager.instance.meshNetwork!
        groups = network.groups
        unicastTargets = network.nodes.map { ($0, $0.elements) }
        
        // Expand a Node with selected Element.
        if let selectedDestination = selectedDestination,
           let node = network.node(withAddress: selectedDestination.address) {
            expandedNodes.insert(node)
        }
        
        // Select the previously selected key, if any.
        if let key = selectedApplicationKey {
            selectedApplicationKey = nil
            let index = model.boundApplicationKeys.firstIndex(of: key) ?? 0
            keySelected(IndexPath(row: index, section: IndexPath.keysSection), initial: true)
        } else {
            keySelected(IndexPath(row: 0, section: IndexPath.keysSection), initial: true)
        }
        
        // Register Nibs for common cells.
        tableView.register(DetailCell.self, forCellReuseIdentifier: "element")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return IndexPath.numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == IndexPath.keysSection {
            return model.boundApplicationKeys.count
        }
        if section == IndexPath.elementsSection {
            // Each Node takes at least 1 row (the Node itself), plus rows for Elements if expanded.
            return unicastTargets.reduce(0) { count, tuple in
                let (node, elements) = tuple
                if expandedNodes.contains(node) {
                    return count + 1 + elements.count
                } else {
                    return count + 1
                }
            }
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
            return "Application Keys"
        case IndexPath.elementsSection:
            return "Unicast Destinations"
        case IndexPath.groupsSection:
            return "Groups"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.isElementsSection && unicastTargets.isEmpty {
            return 56
        }
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard !indexPath.isElementsSection || unicastTargets.count > 0 else {
            return tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath)
        }
        guard !indexPath.isGroupsSection || indexPath.row < groups.count else {
            return tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: indexPath.reuseIdentifier, for: indexPath)
        
        if indexPath.isKeySection {
            let applicationKey = model.boundApplicationKeys[indexPath.row]
            cell.textLabel?.text = applicationKey.name
            cell.detailTextLabel?.text = "Bound to \(applicationKey.boundNetworkKey.name)"
            cell.accessoryType = indexPath == selectedKeyIndexPath ? .checkmark : .none
        }
        if indexPath.isElementsSection {
            // Walk through nodes + expanded state to determine what this row represents
            var row = indexPath.row
            for (node, elements) in unicastTargets {
                if row == 0 {
                    cell.imageView?.image = #imageLiteral(resourceName: "ic_flag_24pt")
                    cell.textLabel?.text = node.name ?? "Unknown Node"
                    cell.detailTextLabel?.text = node.primaryUnicastAddress.asString()
                    cell.accessoryType = .none
                    let expandCollapse = UIImageView(image: UIImage(systemName: expandedNodes.contains(node) ? "chevron.down" : "chevron.right"))
                    expandCollapse.tintColor = .tertiaryLabel
                    cell.accessoryView = expandCollapse
                    cell.selectionStyle = .default
                    cell.separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 0)
                    return cell
                }
                row -= 1
                if expandedNodes.contains(node) {
                    if row < elements.count {
                        let element = elements[row]
                        cell.imageView?.image = nil
                        cell.textLabel?.text = element.name ?? "Element \(element.index + 1)"
                        cell.detailTextLabel?.text = element.unicastAddress.asString()
                        cell.accessoryView = nil
                        cell.accessoryType = element.unicastAddress == selectedDestination?.address ? .checkmark : .none
                        cell.selectionStyle = .default
                        cell.separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 0)
                        return cell
                    }
                    row -= elements.count
                }
            }
        }
        if indexPath.isGroupsSection {
            let group = groups[indexPath.row]
            cell.textLabel?.text = group.name
            cell.detailTextLabel?.text = "0x\(group.address.address.hex)" // Don't show Virtual labels, just 16-bit address.
            cell.accessoryType = group.address == selectedDestination ? .checkmark : .none
        }
        if indexPath.isSpecialGroupsSection {
            let group = Group.specialGroups[indexPath.row]
            cell.textLabel?.text = group.name
            cell.detailTextLabel?.text = "0x\(group.address.address.hex)"
            cell.accessoryType = group.address == selectedDestination ? .checkmark : .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !indexPath.isElementsSection || !unicastTargets.isEmpty else {
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
            keySelected(indexPath, initial: false)
            return
        }
        
        var rows: [IndexPath] = []
        if let previousDestination = selectedDestination,
           let previousIndexPath = self.indexPath(for: previousDestination) {
            rows.append(previousIndexPath)
        }
        
        if indexPath.isElementsSection {
            // Determine if row is a Node or Element
            var row = indexPath.row
            for (node, elements) in unicastTargets {
                if row == 0 {
                    let indexPaths = (1...elements.count).map { IndexPath(row: indexPath.row + $0, section: indexPath.section) }
                    tableView.beginUpdates()
                    if expandedNodes.contains(node) {
                        expandedNodes.remove(node)
                        tableView.deleteRows(at: indexPaths, with: .fade)
                    } else {
                        expandedNodes.insert(node)
                        tableView.insertRows(at: indexPaths, with: .fade)
                    }
                    tableView.reloadRows(at: [indexPath], with: .none)
                    tableView.endUpdates()
                    return
                }
                row -= 1
                if expandedNodes.contains(node) {
                    if row < elements.count {
                        // Element selected
                        let element = elements[row]
                        selectedDestination = MeshAddress(element.unicastAddress)
                        delegate?.destinationSelected(selectedDestination!)
                        
                        rows.append(indexPath)
                        tableView.reloadRows(at: rows, with: .automatic)
                        return
                    }
                    row -= elements.count
                }
            }
        }
        
        if indexPath.isGroupsSection {
            let group = groups[indexPath.row]
            selectedDestination = group.address
            delegate?.destinationSelected(group.address)
            
            rows.append(indexPath)
            tableView.reloadRows(at: rows, with: .automatic)
        }
        
        if indexPath.isSpecialGroupsSection {
            let group = Group.specialGroups[indexPath.row]
            selectedDestination = group.address
            delegate?.destinationSelected(group.address)
            
            rows.append(indexPath)
            tableView.reloadRows(at: rows, with: .automatic)
        }
    }

}

private extension SetPublicationDestinationsViewController {
    
    func keySelected(_ indexPath: IndexPath, initial: Bool) {
        let key = model.boundApplicationKeys[indexPath.row]
        
        var rows: [IndexPath] = []
        if let previousSelection = selectedKeyIndexPath {
            rows.append(previousSelection)
        }
           
        rows.append(indexPath)
        selectedKeyIndexPath = indexPath
        delegate?.keySelected(key)
        
        tableView.reloadRows(at: rows, with: .automatic)
    }
    
    private func indexPath(for address: MeshAddress) -> IndexPath? {
        // Nodes section
        var row = 0
        for (node, elements) in unicastTargets {
            row += 1 // node row itself
            if expandedNodes.contains(node) {
                for element in elements {
                    if element.unicastAddress == address.address {
                        return IndexPath(row: row, section: IndexPath.elementsSection)
                    }
                    row += 1
                }
            }
        }
        
        // Groups section
        for (i, group) in groups.enumerated() {
            if group.address == address {
                return IndexPath(row: i, section: IndexPath.groupsSection)
            }
        }
        
        // Special groups section
        for (i, group) in Group.specialGroups.enumerated() {
            if group.address == address {
                return IndexPath(row: i, section: IndexPath.specialGroupsSection)
            }
        }
        
        return nil
    }
}

private extension IndexPath {
    static let keysSection          = 0
    static let elementsSection      = 1
    static let groupsSection        = 2
    static let specialGroupsSection = 3
    static let numberOfSections = IndexPath.specialGroupsSection + 1
    
    var reuseIdentifier: String {
        if isKeySection {
            return "key"
        }
        if isElementsSection {
            return "element"
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
