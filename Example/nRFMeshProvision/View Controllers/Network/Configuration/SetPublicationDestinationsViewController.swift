//
//  SetPublicationDestinationsViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 04/07/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class SetPublicationDestinationsViewController: UITableViewController {
    
    // MARK: - Properties
    
    var model: Model!
    
    /// List of Elements containing a compatible Model. For example,
    /// for Generic On/Off Server this list will contain all Elements
    /// with Genetic On/Off Client.
    private var compatibleElements: [Element]!
    private let specialGroups = [
        ("All Proxie", 0xFFFC),
        ("All Friends", 0xFFFD),
        ("All Relays", 0xFFFE),
        ("All Nodes", 0xFFFF)
    ]
    private var selectedIndexPath: IndexPath?
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        compatibleElements = meshNetwork.nodes
            .flatMap({ $0.elements })
            .filter({ $0.contains(modelCompatibleWith: model )})
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == IndexPath.elementsSection {
            return compatibleElements.count
        }
        if section == IndexPath.groupsSection {
            return specialGroups.count
        }
        return 0 // TODO: Groups and special groups
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case IndexPath.elementsSection:
            return "Elements"
        case IndexPath.groupsSection:
            return "Groups"
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: indexPath.reuseIdentifier, for: indexPath)
        
        if indexPath.isElementsSection {
            let element = compatibleElements[indexPath.row]
            cell.textLabel?.text = element.name ?? "Element \(indexPath.row + 1)"
            cell.detailTextLabel?.text = element.parentNode!.name ?? "Unknown Device"
        }
        if indexPath.isSpecialGroupsSection {
            let pair = specialGroups[indexPath.row]
            cell.textLabel?.text = pair.0
        }
        cell.accessoryType = indexPath == selectedIndexPath ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedIndexPath = indexPath
        tableView.reloadData()
    }

}

private extension IndexPath {
    static let elementsSection = 0
    static let groupsSection = 1
    static let specialGroupsSection = 1 // 2
    
    var reuseIdentifier: String {
        if isElementsSection {
            return "subtitle"
        }
        return "normal"
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
