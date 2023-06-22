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

class AppKeysViewController: UITableViewController, Editable {
    
    // MARK: - Actions
    
    @IBAction func addTapped(_ sender: UIBarButtonItem) {
        if networkKeyExists {
            performSegue(withIdentifier: "add", sender: nil)
        } else {
            presentAlert(title: "Error",
                         message: "No Network Key found.\n\nCreate a Network Key prior to creating an Application Key.",
                         option: UIAlertAction(title: "Create", style: .default) { [weak self] action in
                            self?.performSegue(withIdentifier: "networkKeys", sender: nil)
                         }
            )
        }
    }
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let generate = UIButtonAction(title: "Generate") {
            self.presentTextAlert(title: "Generate keys",
                                  message: "Specify number of application keys to generate (max 5):",
                                  placeHolder: "E.g. 3", type: .numberRequired,
                                  cancelHandler: nil) { [weak self] value in
                guard let self = self else { return }
                guard let network = MeshNetworkManager.instance.meshNetwork,
                      let number = Int(value), number > 0 else {
                    return
                }
                for i in 0..<min(number, 5) {
                    let key = Data.random128BitKey()
                    _ = try? network.add(applicationKey: key, name: "App Key \(i + 1)")
                }
                self.tableView.reloadData()
                self.hideEmptyView()
            }
        }
        tableView.setEmptyView(title: "No keys",
                               message: "Click + to add a new key.",
                               messageImage: #imageLiteral(resourceName: "baseline-key"),
                               action: generate)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let hasAppKeys = MeshNetworkManager.instance.meshNetwork?.applicationKeys.count ?? 0 > 0
        if !hasAppKeys {
            showEmptyView()
        } else {
            hideEmptyView(false)
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
        viewController.delegate = self
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
        let applicationKeys = MeshNetworkManager.instance.meshNetwork?.applicationKeys ?? []
        return applicationKeys.isEmpty ? 0 : IndexPath.numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let applicationKeys = MeshNetworkManager.instance.meshNetwork?.applicationKeys ?? []
        return applicationKeys.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "appKeyCell", for: indexPath)

        let key = MeshNetworkManager.instance.meshNetwork!.applicationKeys[indexPath.keyIndex]
        cell.textLabel?.text = key.name
        cell.detailTextLabel?.text = "Bound to \(key.boundNetworkKey.name)"

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
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let network = MeshNetworkManager.instance.meshNetwork!
        let applicationKey = network.applicationKeys[indexPath.keyIndex]
        
        // It should not be possible to delete a key that is in use.
        if applicationKey.isUsed(in: network) {
            return UISwipeActionsConfiguration(actions: [
                UIContextualAction(style: .normal, title: "Key in use", handler: { _, _, completionHandler in
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

private extension AppKeysViewController {
    
    var networkKeyExists: Bool {
        let network = MeshNetworkManager.instance.meshNetwork!
        return !network.networkKeys.isEmpty
    }
    
    func deleteKey(at indexPath: IndexPath) {
        let network = MeshNetworkManager.instance.meshNetwork!
        _ = try! network.remove(applicationKeyAt: indexPath.keyIndex)
        
        tableView.beginUpdates()
        tableView.deleteRows(at: [indexPath], with: .top)
        if network.applicationKeys.isEmpty {
            tableView.deleteSections(.keySection, with: .fade)
            showEmptyView()
        }
        tableView.endUpdates()
        
        if !MeshNetworkManager.instance.save() {
            self.presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
        }
    }
    
}

extension AppKeysViewController: EditKeyDelegate {
    
    func keyWasAdded(_ key: Key) {
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        let count = meshNetwork.applicationKeys.count
        
        tableView.beginUpdates()
        if count == 1 {
            tableView.insertSections(.keySection, with: .fade)
            tableView.insertRows(at: [IndexPath(row: 0)], with: .top)
        } else {
            tableView.insertRows(at: [IndexPath(row: count - 1)], with: .top)
        }
        tableView.endUpdates()
        hideEmptyView()
    }
    
    func keyWasModified(_ key: Key) {
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        let applicationKeys = meshNetwork.applicationKeys
        let index = applicationKeys.firstIndex(of: key as! ApplicationKey)
        
        if let index = index {
            let indexPath = IndexPath(row: index, section: 0)
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }
    
}

private extension IndexPath {
    static let keySection = 0
    static let numberOfSections = IndexPath.keySection + 1
    
    /// Returns the Application Key index in mesh network based on the
    /// IndexPath.
    var keyIndex: Int {
        return section + row
    }
    
    init(row: Int) {
        self.init(row: row, section: IndexPath.keySection)
    }
}

private extension IndexSet {
    
    static let keySection = IndexSet(integer: IndexPath.keySection)
    
}
