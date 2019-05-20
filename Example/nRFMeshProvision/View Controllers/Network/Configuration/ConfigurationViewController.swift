//
//  ConfigurationViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 16/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class ConfigurationViewController: UITableViewController {
    var node: Node!

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return node.elements.count > 0 ? 3 : 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return IndexPath.titles.count
        case 1:
            return IndexPath.detailsTitles.count
        case 2:
            return node.elements.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 2:
            return "Elements"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: indexPath.cellIdentifier, for: indexPath)
        cell.textLabel?.text = indexPath.title ?? node.elements[indexPath.row].name ?? "Element \(indexPath.row + 1)"
        
        if indexPath.isName {
            cell.detailTextLabel?.text = node.name
            cell.accessoryType = .disclosureIndicator
        }
        if indexPath.isDetailsSection {
            switch indexPath.row {
            case 0:
                cell.detailTextLabel?.text = node.unicastAddress.asString()
            case 1:
                cell.detailTextLabel?.text = node.deviceKey.hex
            case 2:
                if let id = node.companyIdentifier {
                    cell.detailTextLabel?.text = "\(id.asString())"
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            case 3:
                if let id = node.productIdentifier {
                    cell.detailTextLabel?.text = "\(id.asString())"
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            case 4:
                if let version = node.versionIdentifier {
                    cell.detailTextLabel?.text = "\(version)"
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            case 5:
                if let rpc = node.minimumNumberOfReplayProtectionList {
                    cell.detailTextLabel?.text = "\(rpc)"
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            case 6:
                if let features = node.features {
                    cell.detailTextLabel?.text = "\(features)"
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            default:
                break
            }
        }
        if indexPath.isElementSection {
            cell.detailTextLabel?.text = "\(node.elements[indexPath.row].models.count) models"
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

private extension IndexPath {
    
    static let titles = [
        "Name"
    ]
    static let detailsTitles = [
        "Unicast Address", "Device Key",
        "Company Identifier", "Product Identifier", "Product Version",
        "Replay Protection Count", "Node Features"
    ]
    
    var cellIdentifier: String {
        if isDetailsSection {
            return "subtitle"
        }
        return "normal"
    }
    
    var title: String? {
        if isName {
            return IndexPath.titles[row]
        }
        if isDetailsSection {
            return IndexPath.detailsTitles[row]
        }
        return nil
    }
    
    var isName: Bool {
        return section == 0 && row == 0
    }
    
    var isDetailsSection: Bool {
        return section == 1
    }
    
    var isElementSection: Bool {
        return section == 2
    }
    
}
