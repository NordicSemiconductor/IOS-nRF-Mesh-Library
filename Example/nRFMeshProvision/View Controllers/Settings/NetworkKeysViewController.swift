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
            performSegue(withIdentifier: "add", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let target = segue.destination as! UINavigationController
        let viewController = target.topViewController! as! EditKeyViewController
        viewController.delegate = self
        viewController.isApplicationKey = false
        
        if let cell = sender as? UITableViewCell {
            let indexPath = tableView.indexPath(for: cell)
            let network = MeshNetworkManager.instance.meshNetwork!
            viewController.key = network.networkKeys[indexPath!.keyIndex]
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
        cell.detailTextLabel?.text = key.key.hex

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
        let networkKey = network.networkKeys[indexPath.keyIndex]
        return networkKey.isUsed(in: network) ? .none : .delete
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let network = MeshNetworkManager.instance.meshNetwork!
        let networkKey = network.networkKeys[indexPath.keyIndex]
        
        // It should not be possible to delete a key that is in use.
        if networkKey.isUsed(in: network) {
            let title = networkKey.isPrimary ? "Primary Key" : "Key in use"
            return [UITableViewRowAction(style: .normal, title: title, handler: {_,_ in })]
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteKey(at: indexPath)
        }
    }

}

extension NetworkKeysViewController: EditKeyDelegate {
    
    func keyWasAdded(_ key: Key) {
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        let count = meshNetwork.networkKeys.count
        
        tableView.beginUpdates()
        if count <= 2 {
            // Insert the first or second section.
            tableView.insertSections(IndexSet(integer: count - 1), with: .fade)
        }
        if count == 1 {
            tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
        } else {
            tableView.insertRows(at: [IndexPath(row: count - 2, section: 1)], with: .top)
        }
        tableView.endUpdates()
        hideEmptyView()
    }
    
    func keyWasModified(_ key: Key) {
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        let networkKeys = meshNetwork.networkKeys
        let index = networkKeys.firstIndex(of: key as! NetworkKey)
        
        if let index = index {
            let indexPath = index == 0 ?
                IndexPath(row: 0, section: 0) :
                IndexPath(row: index - 1, section: 1)
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }
    
    private func deleteKey(at indexPath: IndexPath) {
        let network = MeshNetworkManager.instance.meshNetwork!
        _ = try! network.remove(networkKeyAt: indexPath.keyIndex)
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
