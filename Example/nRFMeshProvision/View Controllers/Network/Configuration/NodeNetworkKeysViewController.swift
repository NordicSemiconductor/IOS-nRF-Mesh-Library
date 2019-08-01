//
//  NetworkKeysViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 28/06/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class NodeNetworkKeysViewController: ConnectableViewController, Editable {
    
    // MARK: - Properties
    
    var node: Node!
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEmptyView(title: "No keys", message: "Click + to add a new key.", messageImage: #imageLiteral(resourceName: "baseline-key"))
        refreshControl = UIRefreshControl()
        refreshControl!.tintColor = UIColor.white
        refreshControl!.addTarget(self, action: #selector(readKeys(_:)), for: .valueChanged)
        
        if node.networkKeys.isEmpty {
            showEmptyView()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        MeshNetworkManager.instance.delegate = self
        
        if !node.networkKeys.isEmpty {
            hideEmptyView()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "add" {
            let destination = segue.destination as! UINavigationController
            let viewController = destination.topViewController as! NodeAddNetworkKeyViewController
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
                self.whenConnected() { alert in
                    alert?.message = "Deleting Network Key..."
                    self.deleteNetworkKeyAt(indexPath)
                }
            }
        } else {
            // Otherwise, just try removing it.
            whenConnected() { alert in
                alert?.message = "Deleting Network Key..."
                self.deleteNetworkKeyAt(indexPath)
            }
        }
    }
}

private extension NodeNetworkKeysViewController {
    
    @objc func readKeys(_ sender: Any) {
        whenConnected { alert in
            alert?.message = "Reading Network Keys..."
            MeshNetworkManager.instance.send(ConfigNetKeyGet(), to: self.node)
        }
    }
    
    func deleteNetworkKeyAt(_ indexPath: IndexPath) {
        let networkKey = node.networkKeys[indexPath.row]
        MeshNetworkManager.instance.send(ConfigNetKeyDelete(networkKey: networkKey), to: node)
    }
    
}

extension NodeNetworkKeysViewController: MeshNetworkDelegate {
    
    func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, from source: Address) {
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
            
        case is ConfigNodeReset:
            // The node has been reset remotely.
            (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
            done() {
                self.navigationController?.popToRootViewController(animated: true)
            }
            
        default:
            break
        }
    }
    
}

extension NodeNetworkKeysViewController: NetworkKeyDelegate {
    
    func keyAdded() {
        tableView.reloadData()
    }
    
}
