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

class NodeNetworkKeysViewController: ProgressViewController, Editable {
    
    // MARK: - Outlets and Actions
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    // MARK: - Properties
    
    var node: Node!
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.setEmptyView(title: "No keys",
                               message: "Click + to add a new key.",
                               messageImage: #imageLiteral(resourceName: "baseline-key"))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if node.networkKeys.isEmpty {
            showEmptyView()
        } else {
            hideEmptyView()
        }
        
        // Check if the local Provisioner has configuration capabilities.
        let localProvisioner = MeshNetworkManager.instance.meshNetwork?.localProvisioner
        guard localProvisioner?.hasConfigurationCapabilities ?? false else {
            // The Provisioner cannot sent or receive messages.
            refreshControl = nil
            editButtonItem.isEnabled = false
            addButton.isEnabled = false
            return
        }
        refreshControl = UIRefreshControl()
        refreshControl!.tintColor = UIColor.white
        refreshControl!.addTarget(self, action: #selector(readKeys(_:)), for: .valueChanged)
        
        editButtonItem.isEnabled = true
        addButton.isEnabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        MeshNetworkManager.instance.delegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "add" {
            let navigationController = segue.destination as! UINavigationController
            navigationController.presentationController?.delegate = self
            let viewController = navigationController.topViewController as! NodeAddNetworkKeyViewController
            viewController.node = node
            viewController.delegate = self
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return node.networkKeys.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let key = node.networkKeys[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = key.name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // A Network Key may only be removed with a message signed with another Network Key.
        // This means, that the last Network Key may not be removed.
        // This method returns `true`, but below we return editing style `.none`.
        return true
    }
    
    override func tableView(_ tableView: UITableView,
                            editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return node.networkKeys.count == 1 ? .none : .delete
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if node.networkKeys.count == 1 {
            return UISwipeActionsConfiguration(actions: [
                UIContextualAction(style: .normal, title: "Last Key", handler: { _, _, completionHandler in
                    completionHandler(false)
                })
            ])
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        let networkKey = node.networkKeys[indexPath.row]
        // Show confirmation dialog only when the key is bound to an Application Key.
        if node.contains(applicationKeyBoundToNetworkKey: networkKey) {
            confirm(title: "Remove Key", message: "The selected key is bound to one or more " +
                "Application Keys in the Node. When removed, those keys will also be removed " +
                "and all models bound to them will be unbound, which may cause them to stop working.", handler: { _ in
                self.deleteNetworkKey(networkKey)
            })
        } else {
            // Otherwise, just try removing it.
            deleteNetworkKey(networkKey)
        }
    }
}

extension NodeNetworkKeysViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        MeshNetworkManager.instance.delegate = self
    }
    
}

private extension NodeNetworkKeysViewController {
    
    @objc func readKeys(_ sender: Any) {
        guard let node = node else {
            return
        }
        start("Reading Network Keys...") {
            let message = ConfigNetKeyGet()
            return try MeshNetworkManager.instance.send(message, to: node)
        }
    }
    
    func deleteNetworkKey(_ networkKey: NetworkKey) {
        guard let node = node else {
            return
        }
        start("Deleting Network Key...") {
            let message = ConfigNetKeyDelete(networkKey: networkKey)
            return try MeshNetworkManager.instance.send(message, to: node)
        }
    }
    
}

extension NodeNetworkKeysViewController: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didReceiveMessage message: MeshMessage,
                            sentFrom source: Address, to destination: MeshAddress) {
        // Has the Node been reset remotely.
        guard !(message is ConfigNodeReset) else {
            (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
            done {
                self.navigationController?.popToRootViewController(animated: true)
            }
            return
        }
        // Is the message targeting the current Node?
        guard node.primaryUnicastAddress == source else {
            return
        }
        
        // Handle the message based on its type.
        switch message {

        // Response to Config Net Key Delete.
        case let status as ConfigNetKeyStatus:
            done()
            
            if status.isSuccess {
                tableView.reloadData()
                if node.networkKeys.isEmpty {
                    showEmptyView()
                }
            } else {
                presentAlert(title: "Error", message: "\(status.status)")
            }

        // Response to Config Net Key Get.
        case is ConfigNetKeyList:
            done()
            tableView.reloadData()            
            if node.networkKeys.isEmpty {
                showEmptyView()
            } else {
                hideEmptyView()
            }
            refreshControl?.endRefreshing()
            
        default:
            break
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            failedToSendMessage message: MeshMessage,
                            from localElement: Element, to destination: MeshAddress,
                            error: Error) {
        // Ignore messages sent using model publication.
        guard message is ConfigMessage else {
            return
        }
        done {
            self.presentAlert(title: "Error", message: error.localizedDescription)
            self.refreshControl?.endRefreshing()
        }
    }
    
}

extension NodeNetworkKeysViewController: NetworkKeyDelegate {
    
    func keyAdded() {
        tableView.reloadData()
    }
    
}
