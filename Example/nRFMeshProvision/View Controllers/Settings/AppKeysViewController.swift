//
//  AppKeysViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 18/03/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class AppKeysViewController: UITableViewController, Editable {
    
    // MARK: - Actions
    
    @IBAction func addTapped(_ sender: UIBarButtonItem) {
        if networkKeyExists {
            presentKeyDialog()
        } else {
            presentAlert(title: "Error",
                         message: "No Network Key found.\n\nCreate a Network Key prior to creating an Application Key.",
                         option: UIAlertAction(title: "Create", style: .default, handler: { action in
                            self.performSegue(withIdentifier: "networkKeys", sender: nil)
                         }))
        }
    }
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEmptyView(title: "No keys", message: "Click + to add a new key.", messageImage: #imageLiteral(resourceName: "baseline-key"))
        
        let hasAppKeys = MeshNetworkManager.instance.meshNetwork?.applicationKeys.count ?? 0 > 0
        if !hasAppKeys {
            showEmptyView()
        } else {
            hideEmptyView()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "networkKeys" {
            let target = segue.destination as! NetworkKeysViewController
            target.automaticallyOpenKeyDialog = true
        }
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Configured Keys"
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return MeshNetworkManager.instance.meshNetwork?.applicationKeys.isEmpty ?? false ? 0 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MeshNetworkManager.instance.meshNetwork?.applicationKeys.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "appKeyCell", for: indexPath)

        let key = MeshNetworkManager.instance.meshNetwork!.applicationKeys[indexPath.row]
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
        // It should not be possible to delete a key that is in use.
        let network = MeshNetworkManager.instance.meshNetwork!
        let applicationKey = network.applicationKeys[indexPath.row]
        return !network.nodes.knows(applicationKey: applicationKey)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let network = MeshNetworkManager.instance.meshNetwork!
            _ = try! network.remove(applicationKeyAt: indexPath.row)
            
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .top)
            if network.applicationKeys.isEmpty {
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

extension AppKeysViewController {
    
    private var networkKeyExists: Bool {
        let network = MeshNetworkManager.instance.meshNetwork!
        return !network.networkKeys.isEmpty
    }
    
    private func presentKeyDialog() {
        let network = MeshNetworkManager.instance.meshNetwork!
        let name: String? = "App Key \(network.nextAvailableApplicationKeyIndex + 1)"
        let title = "New App Key"
        let message = """
        Key Index: \(network.nextAvailableApplicationKeyIndex)
        
        Provide a key and human readable name.
        The key must be a 32-character hexadecimal string. A random one has been generated below.
        """
        
        presentKeyDialog(title: title, message: message, name: name) { name, key in
            _ = try! network.add(applicationKey: key, name: name)
            let count = network.applicationKeys.count
            
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
        let appKey = network.applicationKeys[indexPath.row]
        let name = appKey.name
        let title = "Edit Key Name"
        let message = "Key Index: \(appKey.index)"
        
        presentTextAlert(title: title, message: message, text: name,
                         placeHolder: "E.g. Lights and Switches",
                         type: .nameRequired) { name in
                            appKey.name = name
                            
                            self.tableView.reloadRows(at: [indexPath], with: .fade)
                            
                            if !MeshNetworkManager.instance.save() {
                                self.presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
                            }
        }
    }
    
}
