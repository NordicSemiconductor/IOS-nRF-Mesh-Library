//
//  SetPublicationDestinationsViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 04/07/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

protocol DestinationDelegate {
    func keySelected(_ applicationKey: ApplicationKey)
    func destinationSet(to title: String, subtitle: String?, withAddress address: MeshAddress, indexPath: IndexPath)
    func destinationCleared()
}

class SetPublicationDestinationsViewController: UITableViewController {
    
    // MARK: - Properties
    
    var model: Model!
    var delegate: DestinationDelegate?
    var selectedApplicationKey: ApplicationKey!
    var selectedIndexPath: IndexPath?
    
    /// List of Elements containing a compatible Model. For example,
    /// for Generic On/Off Server this list will contain all Elements
    /// with Genetic On/Off Client.
    private var compatibleElements: [Element]!
    private let specialGroups: [(title: String, address: UInt16)] = [
        ("All Proxies", 0xFFFC),
        ("All Friends", 0xFFFD),
        ("All Relays", 0xFFFE),
        ("All Nodes", 0xFFFF)
    ]
    private var selectedKeyIndexPath: IndexPath!
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let key = selectedApplicationKey {
            let index = model.boundApplicationKeys.firstIndex(of: key) ?? 0
            keySelected(IndexPath(row: index, section: IndexPath.keysSection), initial: true)
        } else {
            keySelected(IndexPath(row: 0, section: IndexPath.keysSection), initial: true)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == IndexPath.keysSection {
            return model.boundApplicationKeys.count
        }
        if section == IndexPath.elementsSection {
            return max(compatibleElements.count, 1)
        }
        if section == IndexPath.groupsSection {
            return specialGroups.count
        }
        return 0 // TODO: Groups and special groups
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
            return "Elements from all nodes that contain a compatible model bound to the selected key."
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
        guard !indexPath.isElementsSection || compatibleElements.count > 0 else {
            return tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: indexPath.reuseIdentifier, for: indexPath)
        
        if indexPath.isKeySection {
            let applicationKey = model.boundApplicationKeys[indexPath.row]
            cell.textLabel?.text = applicationKey.name
            cell.detailTextLabel?.text = "Bound to \(applicationKey.boundNetworkKey.name)"
            cell.accessoryType = indexPath == selectedKeyIndexPath ? .checkmark : .none
        }
        if indexPath.isElementsSection {
            let element = compatibleElements[indexPath.row]
            cell.textLabel?.text = element.name ?? "Element \(indexPath.row + 1)"
            cell.detailTextLabel?.text = element.parentNode!.name ?? "Unknown Device"
            cell.accessoryType = indexPath == selectedIndexPath ? .checkmark : .none
        }
        if indexPath.isSpecialGroupsSection {
            let pair = specialGroups[indexPath.row]
            cell.textLabel?.text = pair.title
            cell.accessoryType = indexPath == selectedIndexPath ? .checkmark : .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !indexPath.isElementsSection || !compatibleElements.isEmpty else {
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.isKeySection {
            keySelected(indexPath, initial: false)
            return
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

private extension SetPublicationDestinationsViewController {
    
    func keySelected(_ indexPath: IndexPath, initial: Bool) {
        guard indexPath != selectedKeyIndexPath else {
            return
        }
        
        var rows: [IndexPath] = []
        if let previousSelection = selectedKeyIndexPath {
            rows.append(previousSelection)
        }
        rows.append(indexPath)
        selectedKeyIndexPath = indexPath
        selectedApplicationKey = model.boundApplicationKeys[indexPath.row]
        delegate?.keySelected(selectedApplicationKey)
        
        // If an Element was selected, the selection must be cancelled, as Elements
        // are invalidated.
        if !initial, let indexPath = selectedIndexPath, indexPath.isElementsSection {
            rows.append(indexPath)
            selectedIndexPath = nil
            delegate?.destinationCleared()
        }
        
        tableView.beginUpdates()
        tableView.reloadRows(at: rows, with: .automatic)
        
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        compatibleElements = meshNetwork.nodes
            .flatMap({ $0.elements })
            .filter({ $0.contains(modelCompatibleWith: model, boundTo: selectedApplicationKey) })
        tableView.reloadSections(.elements, with: .automatic)
        tableView.endUpdates()
        
        if let indexPath = selectedIndexPath {
            destinationSelected(indexPath)
        }
    }
    
    func destinationSelected(_ indexPath: IndexPath) {
        switch indexPath.section {
        case IndexPath.elementsSection:
            let element = compatibleElements[indexPath.row]
            let nodeName = element.parentNode!.name ?? "Unknown Device"
            let elementName = element.name ?? "Element \(indexPath.row)"
            delegate?.destinationSet(to: nodeName, subtitle: elementName,
                                     withAddress: MeshAddress(element.unicastAddress),
                                     indexPath: indexPath)
        case IndexPath.specialGroupsSection:
            let selectedGroup = specialGroups[indexPath.row]
            delegate?.destinationSet(to: selectedGroup.title, subtitle: nil,
                                     withAddress: MeshAddress(selectedGroup.address),
                                     indexPath: indexPath)
        default:
            break
        }
    }
}

private extension IndexPath {
    static let keysSection          = 0
    static let elementsSection      = 1
    static let groupsSection        = 2
    static let specialGroupsSection = 2 // 3
    
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
