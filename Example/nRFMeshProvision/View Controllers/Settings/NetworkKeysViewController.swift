//
//  NetworkKeysViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 18/03/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class NetworkKeysViewController: UITableViewController, Editable {
    var automaticallyOpenKeyDialog: Bool = false
    
    // MARK: - Actions
    
    @IBAction func addTapped(_ sender: UIBarButtonItem) {
        presentKeyDialog()
    }
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEmptyView(title: "No keys", message: "Click + to add a new key.", messageImage: #imageLiteral(resourceName: "baseline-key"))
        
        let hasNetKeys = MeshNetworkManager.instance.meshNetwork?.networkKeys.count ?? 0 > 0
        if !hasNetKeys {
            showEmptyView()
        } else {
            hideEmptyView()
        }
        
        if automaticallyOpenKeyDialog {
            presentKeyDialog()
        }
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        let count = MeshNetworkManager.instance.meshNetwork?.networkKeys.count ?? 0
        return min(count, 2)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Primary Network Key"
        default:
            return "Subnetwork Keys"
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let sectionWithFooter = tableView.numberOfSections - 1
        if section == sectionWithFooter {
            return "Swipe left to Rename or Delete a key.\nThe Primary Network Key, or keys used by at least one node or bound to an Application Key may not be deleted."
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = MeshNetworkManager.instance.meshNetwork?.networkKeys.count ?? 0
        switch section {
        case 0:
            return count > 0 ? 1 : 0
        default:
            return count - 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "netKeyCell", for: indexPath)

        let key = MeshNetworkManager.instance.meshNetwork!.networkKeys[indexPath.keyIndex]
        cell.textLabel?.text = key.name
        cell.detailTextLabel?.text = key.key.asString()

        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // The keys in use should not be editable.
        // This will be handled by displaying a "Key in use" action (see methods below).
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        // It should not be possible to delete a key that is in use.
        let network = MeshNetworkManager.instance.meshNetwork!
        let networkKey = network.networkKeys[indexPath.keyIndex]
        let primaryNetworkKey = networkKey.index == 0
        let canBeRemoved = !primaryNetworkKey
                        && !network.nodes.knows(networkKey: networkKey)
                        && !network.applicationKeys.contains(keyBoundTo: networkKey)
        
        let renameRowAction = UITableViewRowAction(style: .default, title: "Rename", handler: { _, indexPath in
            self.presentNameDialog(for: indexPath)
        })
        renameRowAction.backgroundColor = UIColor.nordicLake
        
        if !canBeRemoved {
            let title = primaryNetworkKey ? "Primary Key" : "Key in use"
            return [
                UITableViewRowAction(style: .normal, title: title, handler: {_,_ in }),
                renameRowAction
            ]
        }
        return [
            UITableViewRowAction(style: .destructive, title: "Delete", handler: { _, indexPath in
                self.deleteKey(at: indexPath)
            }),
            renameRowAction
        ]
    }

}

extension NetworkKeysViewController {
    
    private func deleteKey(at indexPath: IndexPath) {
        let network = MeshNetworkManager.instance.meshNetwork!
        _ = try! network.remove(networkKeyAt: indexPath.row)
        let count = network.networkKeys.count
        
        tableView.beginUpdates()
        tableView.deleteRows(at: [indexPath], with: .top)
        if count == 1 {
            tableView.deleteSections(.subnetworkSection, with: .fade)
        }
        if count == 0 {
            tableView.deleteSections(.primaryNetworkSection, with: .fade)
            showEmptyView()
        }
        tableView.endUpdates()
        
        if !MeshNetworkManager.instance.save() {
            self.presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
        }
    }
    
    private func presentKeyDialog() {
        let network = MeshNetworkManager.instance.meshNetwork!
        let name: String? = "Network Key \(network.nextAvailableNetworkKeyIndex + 1)"
        let title = "New Network Key"
        let message = """
        Key Index: \(network.nextAvailableNetworkKeyIndex)
        
        Provide a key and human readable name.
        The key must be a 32-character hexadecimal string. A random one has been generated below.
        """
        
        presentKeyDialog(title: title, message: message, name: name) { name, key in
            _ = try! network.add(networkKey: key, name: name)
            let count = network.networkKeys.count
            
            self.tableView.beginUpdates()
            if count == 2 {
                // The next line is needed to remove the footer from the first section,
                // as it will now appear below the second section.
                self.tableView.reloadSections(.primaryNetworkSection, with: .fade)
            }
            if count <= 2 {
                self.tableView.insertSections(IndexSet(integer: count - 1), with: .fade)
            }            
            if count == 1 {
                self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
            } else {
                self.tableView.insertRows(at: [IndexPath(row: count - 2, section: 1)], with: .top)
            }
            self.tableView.endUpdates()
            self.hideEmptyView()
            
            if !MeshNetworkManager.instance.save() {
                self.presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
            }
        }
    }
    
    private func presentNameDialog(for indexPath: IndexPath) {
        let network = MeshNetworkManager.instance.meshNetwork!
        let netKey = network.networkKeys[indexPath.keyIndex]
        let name = netKey.name
        let title = "Edit Key Name"
        let message = "Key Index: \(netKey.index)"
        
        presentTextAlert(title: title, message: message, text: name,
                         placeHolder: "E.g. Lights and Switches",
                         type: .nameRequired) { name in
                            netKey.name = name
                            
                            self.tableView.reloadRows(at: [indexPath], with: .fade)
                            
                            if !MeshNetworkManager.instance.save() {
                                self.presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
                            }
        }
    }
    
}

private extension IndexPath {
    
    /// Returns the Network Key index in mesh network based on the
    /// IndexPath.
    var keyIndex: Int {
        return section + row
    }
    
}

private extension IndexSet {
    
    static let primaryNetworkSection = IndexSet(integer: 0)
    static let subnetworkSection     = IndexSet(integer: 1)
    
}
