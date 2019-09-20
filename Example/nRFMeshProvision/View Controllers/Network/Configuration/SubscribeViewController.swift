//
//  SubscribeViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 26/07/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

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
        addSubscription()
    }
    
    // MARK: - Properties
    
    var model: Model!
    var delegate: SubscriptionDelegate?
    
    private var groups: [Group]!
    private var selectedIndexPath: IndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEmptyView(title: "No groups", message: "Go to Groups to create a group.", messageImage: #imageLiteral(resourceName: "baseline-groups"))
        
        MeshNetworkManager.instance.delegate = self
        
        let network = MeshNetworkManager.instance.meshNetwork!
        let alreadySubscribedGroups = model.subscriptions
        groups = network.groups.filter {
            !alreadySubscribedGroups.contains($0)
        }
        if groups.isEmpty {
            tableView.showEmptyView()
        }
        // Initially, no group is checked.
        doneButton.isEnabled = false
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "group", for: indexPath)
        cell.textLabel?.text = groups[indexPath.row].name
        cell.accessoryType = indexPath == selectedIndexPath ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
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
    
    func addSubscription() {
        guard let selectedIndexPath = selectedIndexPath else {
            return
        }
        let group = groups[selectedIndexPath.row]
        start("Subscribing...") {
            guard let message: ConfigMessage =
                ConfigModelSubscriptionAdd(group: group, to: self.model) ??
                ConfigModelSubscriptionVirtualAddressAdd(group: group, to: self.model) else {
                    self.done()
                    return
            }
            try? MeshNetworkManager.instance.send(message, to: self.model)
        }
    }
    
}

extension SubscribeViewController: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didReceiveMessage message: MeshMessage,
                            sentFrom source: Address, to destination: Address) {
        // Has the Node been reset remotely.
        guard !(message is ConfigNodeReset) else {
            (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
            done() {
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
        // Is the message targetting the current Node?
        guard model.parentElement.parentNode!.unicastAddress == source else {
            return
        }
        
        // Handle the message based on its type.
        switch message {
            
        case let status as ConfigModelSubscriptionStatus:
            done() {
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
                            from localElement: Element, to destination: Address,
                            error: Error) {
        done() {
            self.presentAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            failedToReceiveResponseForMessage message: AcknowledgedMeshMessage,
                            sentFrom localElement: Element, to destination: Address, error: Error) {
        done() {
            self.presentAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
}
