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
    
    @IBAction func addTapped(_ sender: UIBarButtonItem) {
        presentKeyDialog()
    }
    
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
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Configured Keys"
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return MeshNetworkManager.instance.meshNetwork?.networkKeys.isEmpty ?? false ? 0 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MeshNetworkManager.instance.meshNetwork?.networkKeys.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "netKeyCell", for: indexPath)

        let key = MeshNetworkManager.instance.meshNetwork!.networkKeys[indexPath.row]
        cell.textLabel?.text = key.name
        cell.detailTextLabel?.text = key.key.asString()

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Do not allow to modify the keys after they were created.
        // Only the human readable name can be modified.
        presentNameDialog(for: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // The keys in use should not be editable.
        // This will be handled by displaying a "Key in use" action (see method below).
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        // It should not be possible to delete a key that is in use.
        let network = MeshNetworkManager.instance.meshNetwork!
        let networkKey = network.networkKeys[indexPath.row]
        let canBeRemoved = !network.nodes.knows(networkKey: networkKey)
                        && !network.applicationKeys.contains(keyBoundTo: networkKey)
        
        if !canBeRemoved {
            return [UITableViewRowAction(style: .normal, title: "Key in use", handler: {_,_ in })]
        }
        // By default Delete action will be shown.
        return nil
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let network = MeshNetworkManager.instance.meshNetwork!
            _ = try! network.remove(networkKeyAt: indexPath.row)
            
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .top)
            if network.networkKeys.isEmpty {
                tableView.deleteSections(IndexSet(integer: 0), with: .fade)
                showEmptyView()
            }
            tableView.endUpdates()
            
            if !MeshNetworkManager.instance.save() {
                self.presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
            }
        }
    }

}

extension NetworkKeysViewController {
    
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
            if count == 1 {
                self.tableView.insertSections(IndexSet(integer: 0), with: .fade)
            }
            self.tableView.insertRows(at: [IndexPath(row: count - 1, section: 0)], with: .top)
            self.tableView.endUpdates()
            self.hideEmptyView()
            
            if !MeshNetworkManager.instance.save() {
                self.presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
            }
        }
    }
    
    private func presentNameDialog(for indexPath: IndexPath) {
        let network = MeshNetworkManager.instance.meshNetwork!
        let netKey = network.networkKeys[indexPath.row]
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
