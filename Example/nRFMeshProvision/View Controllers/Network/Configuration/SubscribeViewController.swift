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

class SubscribeViewController: ConnectableViewController {
    
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
        
        MeshNetworkManager.instance.delegate = self
        
        let network = MeshNetworkManager.instance.meshNetwork!
        let alreadySubscribedGroups = model.subscriptions
        groups = network.groups.filter {
            !alreadySubscribedGroups.contains($0)
        }
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
        whenConnected { alert in
            alert?.message = "Subscribing..."
            guard let message: ConfigMessage =
                ConfigModelSubscriptionAdd(group: group, to: self.model) ??
                ConfigModelSubscriptionVirtualAddressAdd(group: group, to: self.model) else {
                    self.done()
                    return
            }
            MeshNetworkManager.instance.send(message, to: self.model)
        }
    }
    
}

extension SubscribeViewController: MeshNetworkDelegate {
    
    func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, from source: Address) {
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
    
}
