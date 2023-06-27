/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import UIKit
import nRFMeshProvision

class NetworkKeysViewController: UITableViewController, Editable {
    var automaticallyOpenKeyDialog: Bool = false
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEmptyView(title: "No keys",
                               message: "Click + to add a new key.",
                               messageImage: #imageLiteral(resourceName: "baseline-key"))
        
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
        return networkKey.isPrimary || networkKey.isUsed(in: network) ? .none : .delete
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let network = MeshNetworkManager.instance.meshNetwork!
        let networkKey = network.networkKeys[indexPath.keyIndex]
        
        // It should not be possible to delete a key that is in use.
        if networkKey.isPrimary || networkKey.isUsed(in: network) {
            let title = networkKey.isPrimary ? "Primary Key" : "Key in use"
            return UISwipeActionsConfiguration(actions: [
                UIContextualAction(style: .normal, title: title, handler: { _, _, completionHandler in
                    completionHandler(false)
                })
            ])
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteKey(at: indexPath)
        }
    }

}

private extension NetworkKeysViewController {
    
    func deleteKey(at indexPath: IndexPath) {
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
            tableView.insertRows(at: [.primaryKey], with: .top)
        } else {
            tableView.insertRows(at: [IndexPath(row: count - 2)], with: .top)
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
                IndexPath.primaryKey :
                IndexPath(row: index - 1)
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }
    
}

private extension IndexPath {
    static let primaryKeySection = 0
    static let otherKeySection   = 1
    
    static let primaryKey = IndexPath(row: 0, section: IndexPath.primaryKeySection)
    
    /// Returns the Network Key index in mesh network based on the
    /// IndexPath.
    var keyIndex: Int {
        return section + row
    }
    
    init(row: Int) {
        self.init(row: row, section: IndexPath.otherKeySection)
    }
    
}

private extension IndexSet {
    
    static let primaryNetworkSection = IndexSet(integer: IndexPath.primaryKeySection)
    static let subnetworkSection     = IndexSet(integer: IndexPath.otherKeySection)
    
}
