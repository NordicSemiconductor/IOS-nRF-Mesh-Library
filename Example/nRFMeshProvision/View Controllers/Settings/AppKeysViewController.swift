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
            performSegue(withIdentifier: "add", sender: nil)
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
            return
        }
        
        let target = segue.destination as! UINavigationController
        let viewController = target.topViewController! as! EditKeyViewController
        viewController.isApplicationKey = true
        
        if let cell = sender as? UITableViewCell {
            let indexPath = tableView.indexPath(for: cell)!
            let network = MeshNetworkManager.instance.meshNetwork!
            viewController.key = network.applicationKeys[indexPath.keyIndex]
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

        let key = MeshNetworkManager.instance.meshNetwork!.applicationKeys[indexPath.keyIndex]
        cell.textLabel?.text = key.name
        cell.detailTextLabel?.text = key.key.asString()

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // The keys in use should not be editable.
        // This will be handled by displaying a "Key in use" action (see methods below).
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let network = MeshNetworkManager.instance.meshNetwork!
        let applicationKey = network.applicationKeys[indexPath.keyIndex]
        return applicationKey.isUsed(in: network) ? .none : .delete
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let network = MeshNetworkManager.instance.meshNetwork!
        let applicationKey = network.applicationKeys[indexPath.keyIndex]
        
        // It should not be possible to delete a key that is in use.
        if applicationKey.isUsed(in: network) {
            return [UITableViewRowAction(style: .normal, title: "Key in use", handler: {_,_ in })]
        }
        return nil
    }

}

extension AppKeysViewController {
    
    private var networkKeyExists: Bool {
        let network = MeshNetworkManager.instance.meshNetwork!
        return !network.networkKeys.isEmpty
    }
    
    private func deleteKey(at indexPath: IndexPath) {
        let network = MeshNetworkManager.instance.meshNetwork!
        _ = try! network.remove(applicationKeyAt: indexPath.keyIndex)
        
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

private extension IndexPath {
    
    /// Returns the Network Key index in mesh network based on the
    /// IndexPath.
    var keyIndex: Int {
        return section + row
    }
    
}
