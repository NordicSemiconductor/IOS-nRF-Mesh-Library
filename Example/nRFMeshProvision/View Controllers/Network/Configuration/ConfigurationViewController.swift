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
    
    private var alert: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = node.name ?? "Unknown device"
        
        let manager = MeshNetworkManager.instance
        manager.delegate = self
        // If the Composition Data were never obtained, get them now.
        if node.companyIdentifier == nil {
            manager.send(ConfigCompositionDataGet(), to: node)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return IndexPath.titles.count
        case 1:
            return max(1, node.elements.count)
        case 2:
            return IndexPath.detailsTitles.count
        case 3:
            return 1 // Reset button
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return "Elements"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 3:
            return "Resetting the node will change its state back to un-provisioned state."
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: indexPath.cellIdentifier, for: indexPath)
        
        if indexPath.isName {
            cell.textLabel?.text = indexPath.title
            cell.detailTextLabel?.text = node.name ?? "No name"
            cell.accessoryType = .disclosureIndicator
        }
        if indexPath.isDetailsSection {
            cell.textLabel?.text = indexPath.title
            switch indexPath.row {
            case 0:
                cell.detailTextLabel?.text = node.unicastAddress.asString()
            case 1:
                cell.detailTextLabel?.text = node.deviceKey.hex
            case 2:
                if let id = node.companyIdentifier {
                    let name = CompanyIdentifier.name(for: id)
                    cell.detailTextLabel?.text = "\(id.asString()) - " + (name != nil ? name! : "Unknown")
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
            if node.elements.count > indexPath.row {
                let element = node.elements[indexPath.row]
                cell.textLabel?.text = element.name ?? "Element \(indexPath.row + 1)"
                cell.detailTextLabel?.text = "\(element.models.count) models"
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
            } else {
                cell.textLabel?.text = "Composition Data not received."
                cell.detailTextLabel?.text = nil
                cell.accessoryType = .none
                cell.selectionStyle = .none
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if !indexPath.isDetailsSection || indexPath.isDeviceKey {
            return true
        }
        return false
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.isName {
            presentNameDialog()
        }
        if indexPath.isReset {
            presentResetConfirmation()
        }
        if indexPath.isDeviceKey {
            UIPasteboard.general.string = node.deviceKey.hex
            showToast("Device Key copied to Clipboard.", delay: .shortDelay)
        }
    }

}

private extension ConfigurationViewController {

    /// Presents a dialog to edit the node name.
    func presentNameDialog() {
        presentTextAlert(title: "Name", message: nil, text: node.name,
                         placeHolder: "E.g. Bedroom Light", type: .name) { name in
                            if name.isEmpty {
                                self.node.name = nil
                            } else {
                                self.node.name = name
                            }
                            
                            if MeshNetworkManager.instance.save() {
                                self.title = self.node.name ?? "Unknown device"
                                self.tableView.reloadRows(at: [.name], with: .automatic)
                            } else {
                                self.presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
                            }
        }
    }
    
    /// Presents a dialog with resetting confirmation.
    func presentResetConfirmation() {
        let alert = UIAlertController(title: "Reset Node",
                                      message: "Resetting the node will change its state back to unprovisioned state.",
                                      preferredStyle: .actionSheet)
        let resetAction = UIAlertAction(title: "Reset", style: .destructive) { _ in self.resetNode() }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(resetAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    /// Sends a message to the node that will reset its state to unprovisioned.
    func resetNode() {
        MeshNetworkManager.instance.send(ConfigNodeReset(), to: node)
    }
    
}

extension ConfigurationViewController: MeshNetworkDelegate {
    
    func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, from source: Address) {
        switch message {
        case let compositionDataStatus as ConfigCompositionDataStatus:
            if let page0 = compositionDataStatus.page as? Page0 {
                page0.apply(to: node)
                
                if !MeshNetworkManager.instance.save() {
                    self.presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
                }
                tableView.reloadData()
            }
        case is ConfigNodeResetStatus:
            MeshNetworkManager.instance.meshNetwork!.remove(node: node)
            navigationController?.popViewController(animated: true)
        default:
            break
        }
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
        if isReset {
            return "reset"
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
    
    var isReset: Bool {
        return section == 3 && row == 0
    }
    
    var isDeviceKey: Bool {
        return section == 2 && row == 1
    }
    
    var isElementSection: Bool {
        return section == 1
    }
    
    var isDetailsSection: Bool {
        return section == 2
    }
    
    static let name = IndexPath(row: 0, section: 0)
}
