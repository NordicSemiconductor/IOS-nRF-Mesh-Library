//
//  NodeAppKeysViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 28/06/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class NodeAppKeysViewController: ProgressViewController, Editable {
    
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
        
        if node.applicationKeys.isEmpty {
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
        
        if !node.networkKeys.isEmpty {
            refreshControl = UIRefreshControl()
            refreshControl!.tintColor = UIColor.white
            refreshControl!.addTarget(self, action: #selector(readKeys(_:)), for: .valueChanged)
            
            editButtonItem.isEnabled = true
            addButton.isEnabled = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        MeshNetworkManager.instance.delegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "add" {
            let destination = segue.destination as! UINavigationController
            let viewController = destination.topViewController as! NodeAddAppKeyViewController
            viewController.node = node
            viewController.delegate = self
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return node.applicationKeys.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let key = node.applicationKeys[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = key.name
        cell.detailTextLabel?.text = "Bound to \(key.boundNetworkKey.name)"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        // This is required to allow swipe to delete action.
        return nil
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let applicationKey = node.applicationKeys[indexPath.row]
        // Show confirmation dialog only when the key is bound to some Models.
        if node.hasModelBoundTo(applicationKey) {
            confirm(title: "Remove Key", message: "The selected key is bound to one or more models in the Node. When removed, it will be unbound automatically, and the models may stop working.") { _ in
                self.start("Deleting Application Key...") {
                    self.deleteApplicationKeyAt(indexPath)
                }
            }
        } else {
            // Otherwise, just try removing it.
            start("Deleting Application Key...") {
                self.deleteApplicationKeyAt(indexPath)
            }
        }
    }
}

private extension NodeAppKeysViewController {
    
    @objc func readKeys(_ sender: Any) {
        start("Reading Application Keys...") {
            try? MeshNetworkManager.instance.send(ConfigAppKeyGet(networkKey: self.node.networkKeys.first!), to: self.node)
        }
    }
    
    func deleteApplicationKeyAt(_ indexPath: IndexPath) {
        let applicationKey = node.applicationKeys[indexPath.row]
        try? MeshNetworkManager.instance.send(ConfigAppKeyDelete(applicationKey: applicationKey), to: node)
    }
    
}

extension NodeAppKeysViewController: MeshNetworkDelegate {
    
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
        case let status as ConfigAppKeyStatus:
            done()
            
            if status.isSuccess {
                tableView.reloadData()
                if node.applicationKeys.isEmpty {
                    showEmptyView()
                }
            } else {
                presentAlert(title: "Error", message: "\(status.status)")
            }
            
        case let list as ConfigAppKeyList:
            if list.isSuccess {
                let index = node.networkKeys.firstIndex { $0.index == list.networkKeyIndex }
                if let index = index, index + 1 < node.networkKeys.count {
                    try? MeshNetworkManager.instance.send(ConfigAppKeyGet(networkKey: node.networkKeys[index + 1]), to: node)
                } else {
                    done()
                    tableView.reloadData()
                    if node.applicationKeys.isEmpty {
                        showEmptyView()
                    }
                    refreshControl?.endRefreshing()
                }
            } else {
                done() {
                    self.presentAlert(title: "Error", message: "\(list.status)")
                    self.refreshControl?.endRefreshing()
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
            self.refreshControl?.endRefreshing()
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            failedToReceiveResponseForMessage message: AcknowledgedMeshMessage,
                            sentFrom localElement: Element, to destination: Address, error: Error) {
        done() {
            self.presentAlert(title: "Error", message: error.localizedDescription)
            self.refreshControl?.endRefreshing()
        }
    }
    
}

extension NodeAppKeysViewController: AppKeyDelegate {
    
    func keyAdded() {
        tableView.reloadData()
        
        if !node.applicationKeys.isEmpty {
            hideEmptyView()
        }
    }
    
}
