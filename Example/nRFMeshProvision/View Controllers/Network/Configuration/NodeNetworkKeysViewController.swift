//
//  NetworkKeysViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 28/06/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

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
        
        tableView.setEmptyView(title: "No keys", message: "Click + to add a new key.", messageImage: #imageLiteral(resourceName: "baseline-key"))
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
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return node.networkKeys.count == 1 ? .none : .delete
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if node.networkKeys.count == 1 {
            return [UITableViewRowAction(style: .normal, title: "Last Key", handler: {_,_ in })]
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let networkKey = node.networkKeys[indexPath.row]
        // Show confirmation dialog only when the key is bound to an Application Key.
        if node.hasApplicationKeyBoundTo(networkKey) {
            confirm(title: "Remove Key", message: "The selected key is bound to one or more Application Keys in the Node. When removed, those keys will also be removed and all models bound to them will be unbound, which may cause them to stop working.") { _ in
                self.deleteNetworkKey(networkKey)
            }
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
        start("Reading Network Keys...") {
            let message = ConfigNetKeyGet()
            return try MeshNetworkManager.instance.send(message, to: self.node)
        }
    }
    
    func deleteNetworkKey(_ networkKey: NetworkKey) {
        start("Deleting Network Key...") {
            let message = ConfigNetKeyDelete(networkKey: networkKey)
            return try MeshNetworkManager.instance.send(message, to: self.node)
        }
    }
    
}

extension NodeNetworkKeysViewController: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didReceiveMessage message: MeshMessage,
                            sentFrom source: Address, to destination: Address) {
        // Has the Node been reset remotely.
        guard !(message is ConfigNodeReset) else {
            (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
            done() {
                self.navigationController?.popToRootViewController(animated: true)
            }
            return
        }
        // Is the message targetting the current Node?
        guard node.unicastAddress == source else {
            return
        }
        
        // Handle the message based on its type.
        switch message {
            
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
            
        case is ConfigNetKeyList:
            done()
            tableView.reloadData()            
            if node.networkKeys.isEmpty {
                showEmptyView()
            }
            refreshControl?.endRefreshing()
            
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
            self.refreshControl?.endRefreshing()
        }
    }
    
}

extension NodeNetworkKeysViewController: NetworkKeyDelegate {
    
    func keyAdded() {
        tableView.reloadData()
    }
    
}
