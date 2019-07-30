//
//  NodeAppKeysViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 28/06/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class NodeAppKeysViewController: ConnectableViewController, Editable {
    
    // MARK: - Properties
    
    var node: Node!
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEmptyView(title: "No keys", message: "Click + to add a new key.", messageImage: #imageLiteral(resourceName: "baseline-key"))
        if !node.networkKeys.isEmpty {
            refreshControl = UIRefreshControl()
            refreshControl!.tintColor = UIColor.white
            refreshControl!.addTarget(self, action: #selector(readKeys(_:)), for: .valueChanged)
        }
        
        if node.applicationKeys.isEmpty {
            showEmptyView()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        MeshNetworkManager.instance.delegate = self
        
        if !node.applicationKeys.isEmpty {
            hideEmptyView()
        }
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
                self.whenConnected() { alert in
                    alert?.message = "Deleting Application Key..."
                    self.deleteApplicationKeyAt(indexPath)
                }
            }
        } else {
            // Otherwise, just try removing it.
            whenConnected() { alert in
                alert?.message = "Deleting Application Key..."
                self.deleteApplicationKeyAt(indexPath)
            }
        }
    }
}

private extension NodeAppKeysViewController {
    
    @objc func readKeys(_ sender: Any) {
        whenConnected { alert in
            alert?.message = "Reading Application Keys..."
            MeshNetworkManager.instance.send(ConfigAppKeyGet(networkKey: self.node.networkKeys.first!), to: self.node)
        }
    }
    
    func deleteApplicationKeyAt(_ indexPath: IndexPath) {
        let applicationKey = node.applicationKeys[indexPath.row]
        MeshNetworkManager.instance.send(ConfigAppKeyDelete(applicationKey: applicationKey), to: node)
    }
    
}

extension NodeAppKeysViewController: MeshNetworkDelegate {
    
    func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, from source: Address) {
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
                    MeshNetworkManager.instance.send(ConfigAppKeyGet(networkKey: node.networkKeys[index + 1]), to: node)
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
    
}

extension NodeAppKeysViewController: AppKeyDelegate {
    
    func keyAdded() {
        tableView.reloadData()
    }
    
}
