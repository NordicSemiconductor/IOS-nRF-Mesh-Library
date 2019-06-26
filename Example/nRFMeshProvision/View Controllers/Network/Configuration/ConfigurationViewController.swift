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
    
    // MARK: - Outlets and Actions
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Public properties
    
    var node: Node!
    
    // MARK: - Private properties
    
    private var alert: UIAlertController?
    
    // MARK: - Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = node.name ?? "Unknown device"
        
        MeshNetworkManager.bearer.delegate = self
        let manager = MeshNetworkManager.instance
        manager.delegate = self
        // If the Composition Data were never obtained, get them now.
        if !node.isConfigured {
            let connected = MeshNetworkManager.bearer.isConnected
            let status = connected ? "Requesting Composition Data..." : "Connecting..."
            alert = UIAlertController(title: "Status", message: status, preferredStyle: .alert)
            alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert!, animated: true) {
                // This message will be enqueued and sent when we are connected
                // to the mesh network.
                manager.send(ConfigCompositionDataGet(page: 0xFF), to: self.node)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Element name might have been updated.
        tableView.reloadSections(IndexSet.elementsSection, with: .automatic)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showElement" {
            let indexPath = sender as! IndexPath
            let destination = segue.destination as! ElementsViewController
            destination.element = node.elements[indexPath.row]
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return IndexPath.numberOfSection
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case IndexPath.nameSection:
            return IndexPath.titles.count
        case IndexPath.nodeSection:
            return IndexPath.nodeTitles.count
        case IndexPath.elementsSection:
            if node.isConfigured {
                return node.elements.count
            }
            return 1 // "Composition Data not received" message
        case IndexPath.compositionDataSection:
            return IndexPath.detailsTitles.count
        case IndexPath.actionsSection:
            return 1 // Reset button
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case IndexPath.elementsSection:
            return "Elements"
        case IndexPath.compositionDataSection:
            return "Composition Data"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case IndexPath.actionsSection:
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
        if indexPath.isNodeSection {
            cell.textLabel?.text = indexPath.title
            switch indexPath.row {
            case 0:
                cell.detailTextLabel?.text = node.unicastAddress.asString()
            case 1:
                cell.detailTextLabel?.text = node.defaultTTL != nil ? "\(node.defaultTTL!)" : "Unknown"
            case 2:
                cell.detailTextLabel?.text = node.deviceKey.hex
            default:
                break
            }
        }
        if indexPath.isDetailsSection {
            cell.textLabel?.text = indexPath.title
            switch indexPath.row {
            case 0:
                if let id = node.companyIdentifier {
                    let name = CompanyIdentifier.name(for: id)
                    cell.detailTextLabel?.text = "\(id.asString()) - " + (name != nil ? name! : "Unknown")
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            case 1:
                if let id = node.productIdentifier {
                    cell.detailTextLabel?.text = "\(id.asString())"
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            case 2:
                if let version = node.versionIdentifier {
                    cell.detailTextLabel?.text = "\(version)"
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            case 3:
                if let rpc = node.minimumNumberOfReplayProtectionList {
                    cell.detailTextLabel?.text = "\(rpc)"
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            case 4:
                if let featuresCell = cell as? NodeFeaturesCell {
                   featuresCell.node = node
                }
            default:
                break
            }
        }
        if indexPath.isElementSection {
            if node.isConfigured {
                let element = node.elements[indexPath.row]
                cell.textLabel?.text = element.name ?? "Element \(element.index + 1)"
                cell.textLabel?.textColor = .darkText
                cell.detailTextLabel?.text = "\(element.models.count) models"
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.textLabel?.text = "Composition Data not received"
                cell.textLabel?.textColor = .lightGray
                cell.detailTextLabel?.text = nil
                cell.accessoryType = .none
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.isHighlightable
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.isName {
            presentNameDialog()
        }
        if indexPath.isDeviceKey {
            UIPasteboard.general.string = node.deviceKey.hex
            showToast("Device Key copied to Clipboard.", delay: .shortDelay)
        }
        if indexPath.isElementSection {
            performSegue(withIdentifier: "showElement", sender: indexPath)
        }
        if indexPath.isReset {
            presentResetConfirmation(from: indexPath)
        }
    }

}

extension ConfigurationViewController: GattBearerDelegate {
    
    func bearerDidConnect(_ bearer: Bearer) {
        DispatchQueue.main.async {
            self.alert?.message = "Discovering services..."
        }
    }
    
    func bearerDidDiscoverServices(_ bearer: Bearer) {
        DispatchQueue.main.async {
            self.alert?.message = "Initializing..."
        }
    }
    
    func bearerDidOpen(_ bearer: Bearer) {
        DispatchQueue.main.async {
            self.alert?.message = "Requesting Composition Data..."
        }
    }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        DispatchQueue.main.async {
            self.alert?.dismiss(animated: true)
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
    func presentResetConfirmation(from indexPath: IndexPath) {
        let alert = UIAlertController(title: "Reset Node",
                                      message: "Resetting the node will change its state back to unprovisioned state.",
                                      preferredStyle: .actionSheet)
        let resetAction = UIAlertAction(title: "Reset", style: .destructive) { _ in self.resetNode() }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(resetAction)
        alert.addAction(cancelAction)
        let cell = tableView.cellForRow(at: indexPath)
        alert.popoverPresentationController?.sourceView = (cell as? ResetNodeCell)?.resetButton ?? cell
        alert.popoverPresentationController?.permittedArrowDirections = [.down, .up, .right]
        present(alert, animated: true)
    }
    
    /// Sends a message to the node that will reset its state to unprovisioned.
    func resetNode() {
        activityIndicator.startAnimating()
        MeshNetworkManager.instance.send(ConfigNodeReset(), to: self.node)
    }
    
}

extension ConfigurationViewController: MeshNetworkDelegate {
    
    func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, from source: Address) {
        switch message {
        case let compositionDataStatus as ConfigCompositionDataStatus:
            node.apply(compositionData: compositionDataStatus)
            tableView.reloadData()
            alert?.message = "Requesting default TTL..."
            // Composition Data is ready, let's read the TTL.
            MeshNetworkManager.instance.send(ConfigDefaultTtlGet(), to: node)
        case let defaultTtlStatus as ConfigDefaultTtlStatus:
            node.apply(defaultTtl: defaultTtlStatus)
            tableView.reloadRows(at: [.ttl], with: .automatic)
            alert?.dismiss(animated: true)
            
            if !MeshNetworkManager.instance.save() {
                presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
            }
        case is ConfigNodeResetStatus:
            MeshNetworkManager.instance.meshNetwork!.remove(node: node)
            activityIndicator.stopAnimating()
            
            if MeshNetworkManager.instance.save() {
                navigationController?.popViewController(animated: true)
            } else {
                presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
            }
        default:
            break
        }
    }
    
}

private extension IndexPath {
    static let nameSection = 0
    static let nodeSection = 1
    static let elementsSection = 2
    static let compositionDataSection = 3
    static let actionsSection = 4
    static let numberOfSection = IndexPath.actionsSection + 1
    
    static let titles = [
        "Name"
    ]
    static let nodeTitles = [
        "Unicast Address", "TTL", "Device Key"
    ]
    static let detailsTitles = [
        "Company Identifier", "Product Identifier", "Product Version",
        "Replay Protection Count", nil // Node Features is using its own cell.
    ]
    
    var cellIdentifier: String {
        if isNodeFeatures {
            return "features"
        }
        if isDeviceKey {
            return "key"
        }
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
        if isNodeSection {
            return IndexPath.nodeTitles[row]
        }
        if isDetailsSection {
            return IndexPath.detailsTitles[row]
        }
        return nil
    }
    
    var isHighlightable: Bool {
        return isName || isDeviceKey || isElementSection || isReset
    }
    
    var isName: Bool {
        return section == IndexPath.nameSection && row == 0
    }
    
    var isReset: Bool {
        return section == IndexPath.actionsSection && row == 0
    }
    
    var isUnicastAddress: Bool {
        return isNodeSection && row == 0
    }
    
    var isTtl: Bool {
        return isNodeSection && row == 1
    }
    
    var isDeviceKey: Bool {
        return isNodeSection && row == 2
    }
    
    var isNodeFeatures: Bool {
        return isDetailsSection && row == 4
    }
    
    var isNodeSection: Bool {
        return section == IndexPath.nodeSection
    }
    
    var isElementSection: Bool {
        return section == IndexPath.elementsSection
    }
    
    var isDetailsSection: Bool {
        return section == IndexPath.compositionDataSection
    }
    
    static let name  = IndexPath(row: 0, section: IndexPath.nameSection)
    static let ttl   = IndexPath(row: 1, section: IndexPath.nodeSection)
    static let reset = IndexPath(row: 0, section: IndexPath.actionsSection)
    
}

private extension IndexSet {
    
    static let elementsSection = IndexSet(integer: IndexPath.elementsSection)
    
}
