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
import NordicMesh

protocol AppKeyDelegate {
    /// This method is called when a new Application Key has been added to the Node.
    func keyAdded()
}

class NodeAddAppKeyViewController: ProgressViewController {
    
    // MARK: - Outlets and Actions
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        guard let selectedIndexPath = selectedIndexPath else {
            return
        }
        switch selectedIndexPath.section {
        case 0:
            let selectedAppKey = keys[selectedIndexPath.row]
            addKey(selectedAppKey)
        case 1:
            let selectedAppKey = otherKeys[selectedIndexPath.row]
            addKey(selectedAppKey.boundNetworkKey)
        default:
            break
        }
    }
    
    // MARK: - Properties
    
    var node: Node!
    var delegate: AppKeyDelegate?
    
    /// Keys that have Network Keys known to the Node.
    private var keys: [ApplicationKey]!
    /// Keys which bound Network Keys are not known to the Node.
    private var otherKeys: [ApplicationKey]!
    /// The index path of the selected key.
    private var selectedIndexPath: IndexPath?
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let presentApplicationKeysSettings = UIButtonAction(title: "Settings") { [weak self] in
            guard let self = self else { return }
            let tabBarController = self.presentingViewController as? RootTabBarController
            self.dismiss(animated: true) {
                tabBarController?.presentApplicationKeysSettings()
            }
        }
        tableView.setEmptyView(title: "No keys available",
                               message: "Go to Settings to create a new key,\nor add a bound Network Key first.",
                               messageImage: #imageLiteral(resourceName: "baseline-key"),
                               action: presentApplicationKeysSettings)
        
        MeshNetworkManager.instance.delegate = self
        
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        let availableKeys = meshNetwork.applicationKeys.notKnownTo(node: node)
        keys = availableKeys.filter { node.knows(networkKey: $0.boundNetworkKey) }
        otherKeys = availableKeys.filter { !node.knows(networkKey: $0.boundNetworkKey) }
        if keys.isEmpty && otherKeys.isEmpty {
            tableView.showEmptyView()
        }
        // Initially, no key is checked.
        doneButton.isEnabled = false
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if keys.isEmpty && otherKeys.isEmpty {
            return 0
        }
        return 1 + (otherKeys.isEmpty ? 0 : 1)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:  return "Keys bound to known subnets"
        case 1:  return "Keys bound to other subnets"
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0 where keys.isEmpty:
            return "Go to Settings to create a new key."
        case 1:
            return "Note: The corresponding bound Network Key will be added to the node automatically."
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return max(1, keys.count) // At lease "No keys available" message.
        case 1: return otherKeys.count
        default: fatalError("Invalid section")
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == 1 || !keys.isEmpty else {
            return tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath)
        }
        let key = indexPath.section == 0 ? keys[indexPath.row] : otherKeys[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = key.name
        cell.detailTextLabel?.text = "Bound to \(key.boundNetworkKey.name)"
        cell.accessoryType = indexPath == selectedIndexPath ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1 || !keys.isEmpty
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var rows: [IndexPath] = []
        if let selectedIndexPath = selectedIndexPath {
            rows.append(selectedIndexPath)
        }
        rows.append(indexPath)
        selectedIndexPath = indexPath
        tableView.reloadRows(at: rows, with: .automatic)
        
        doneButton.isEnabled = true
    }
}

private extension NodeAddAppKeyViewController {
    
    /// Adds the given Network Key to the target Node.
    ///
    /// - parameter networkKey: The Network Key to be added.
    func addKey(_ networkKey: NetworkKey) {
        guard let node = node else {
            return
        }
        start("Adding Network Key...") {
            let message = ConfigNetKeyAdd(networkKey: networkKey)
            return try MeshNetworkManager.instance.send(message, to: node)
        }
    }
    
    /// Adds the given Application Key to the target Node.
    ///
    /// - parameter applicationKey: The Application Key to be added.
    func addKey(_ applicationKey: ApplicationKey) {
        guard let node = node else {
            return
        }
        start("Adding Application Key...") {
            let message = ConfigAppKeyAdd(applicationKey: applicationKey)
            return try MeshNetworkManager.instance.send(message, to: node)
        }
    }
    
}

extension NodeAddAppKeyViewController: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didReceiveMessage message: MeshMessage,
                            sentFrom source: Address, to destination: MeshAddress) {
        // Has the Node been reset remotely.
        guard !(message is ConfigNodeReset) else {
            (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
            done {
                let rootViewControllers = self.presentingViewController?.children
                self.dismiss(animated: true) {
                    rootViewControllers?.forEach {
                        if let navigationController = $0 as? UINavigationController {
                            navigationController.popToRootViewController(animated: true)
                        }
                    }
                }
            }
            return
        }
        // Is the message targeting the current Node?
        guard node.primaryUnicastAddress == source else {
            return
        }
        
        // Handle the message based on its type.
        switch message {
            
        case let status as ConfigNetKeyStatus:
            guard status.isSuccess else {
                done {
                    self.presentAlert(title: "Error", message: status.message)
                }
                break
            }
            let selectedKey = otherKeys[selectedIndexPath!.row]
            addKey(selectedKey)
            
        case let status as ConfigAppKeyStatus:
            done {
                if status.isSuccess {
                    self.dismiss(animated: true)
                    self.delegate?.keyAdded()
                } else {
                    self.presentAlert(title: "Error", message: status.message)
                }
            }
            
        default:
            // Ignore
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
        }
    }
    
}
