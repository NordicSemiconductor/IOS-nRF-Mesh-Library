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

protocol SubscriptionDelegate {
    /// This method is called when a new subscription was added.
    func subscriptionAdded()
}

class SubscribeViewController: ProgressViewController {
    
    // MARK: - Outlets & Actions
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        guard let selectedIndexPath = selectedIndexPath else {
            return
        }
        let groupSet: [Group] = selectedIndexPath.section == 0 ? groups : specialGroups
        let group = groupSet[selectedIndexPath.row]
        addSubscription(to: group)
    }
    
    // MARK: - Properties
    
    var model: Model!
    var delegate: SubscriptionDelegate?
    
    private var groups: [Group]!
    private var specialGroups: [Group]!
    private var selectedIndexPath: IndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        MeshNetworkManager.instance.delegate = self
        
        let network = MeshNetworkManager.instance.meshNetwork!
        let alreadySubscribedGroups = model.subscriptions
        groups = network.groups
            .filter { !alreadySubscribedGroups.contains($0) }
        specialGroups = Group.specialGroups
            .filter { $0 != .allNodes }
            .filter { !alreadySubscribedGroups.contains($0) }
        // Initially, no group is checked.
        doneButton.isEnabled = false
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if !specialGroups.isEmpty {
            return 2
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Groups"
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 && !specialGroups.isEmpty {
            if model.parentElement?.isPrimary ?? false {
                return """
                       All models on the primary Element are automatically subscribed to the All\u{00a0}Nodes \
                       address and those of the groups listed above which have the corresponding feature \
                       enabled on the node.
                                       
                       Subscribing to any of the groups will bypass the feature check so that the model \
                       will always receive messages sent to that group.
                       """
            } else {
                return """
                       Models on a non-primary Element may be subscribed to any of the above-listed groups, \
                       but the corresponding feature will not be checked.
                       
                       It is not possible to subscribe any model to the All\u{00a0}Nodes address.
                       """
            }
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return specialGroups.count
        }
        return groups.count + 1 // 1 for Add Group button
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section != 0 || indexPath.row < groups.count else {
            return tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "group", for: indexPath)
        let groupSet = indexPath.section == 0 ? groups! : specialGroups!
        let group = groupSet[indexPath.row]
        cell.textLabel?.text = group.name
        cell.accessoryType = indexPath == selectedIndexPath ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Add Group clicked.
        if indexPath.section == 0 && indexPath.row == groups.count {
            let tabBarController = presentingViewController as? RootTabBarController
            dismiss(animated: true) {
                tabBarController?.presentGroups()
            }
            return
        }

        // A group clicked.
        var rows: [IndexPath] = []
        if let previousSelection = selectedIndexPath {
            rows.append(previousSelection)
        }
        rows.append(indexPath)
        selectedIndexPath = indexPath
        
        tableView.reloadRows(at: rows, with: .automatic)
        doneButton.isEnabled = true
    }

}

private extension SubscribeViewController {
    
    func addSubscription(to group: Group) {
        guard let model = model,
              let node = model.parentElement?.parentNode else {
            return
        }
        start("Subscribing...") {
            let message: AcknowledgedConfigMessage =
                ConfigModelSubscriptionAdd(group: group, to: model) ??
                ConfigModelSubscriptionVirtualAddressAdd(group: group, to: model)!
            return try MeshNetworkManager.instance.send(message, to: node)
        }
    }
    
}

extension SubscribeViewController: MeshNetworkDelegate {
    
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
        guard model.parentElement?.parentNode?.primaryUnicastAddress == source else {
            return
        }
        
        // Handle the message based on its type.
        switch message {
            
        case let status as ConfigModelSubscriptionStatus:
            done {
                if status.status == .success {
                    self.dismiss(animated: true)
                    self.delegate?.subscriptionAdded()
                } else {
                    self.presentAlert(title: "Error", message: status.message)
                }
            }
            
        default:
            break
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            failedToSendMessage message: MeshMessage,
                            from localElement: Element, to destination: MeshAddress,
                            error: Error) {
        // Ignore messages sent from model publication.
        guard message is ConfigMessage else {
            return
        }
        done {
            self.presentAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
}
