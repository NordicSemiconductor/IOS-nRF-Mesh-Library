//
//  GroupsViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 18/07/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class GroupsViewController: UITableViewController, Editable {
    
    // MARK: - Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEmptyView(title: "No Groups", message: "Click + to create one.", messageImage: #imageLiteral(resourceName: "baseline-groups"))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        
        let network = MeshNetworkManager.instance.meshNetwork
        let hasGroups = network?.groups.count ?? 0 > 0
        if !hasGroups {
            showEmptyView()
        } else {
            hideEmptyView()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addGroup" {
            let destination = segue.destination as! UINavigationController
            let viewController = destination.topViewController as! AddGroupViewController
            viewController.delegate = self
        } else if segue.identifier == "show" {
            let destination = segue.destination as! GroupControlViewController
            let cell = sender as! GroupCell
            destination.group = cell.group
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let meshNetwork = MeshNetworkManager.instance.meshNetwork
        return meshNetwork?.groups.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "group", for: indexPath) as! GroupCell
        cell.group = MeshNetworkManager.instance.meshNetwork!.groups[indexPath.row]        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let network = MeshNetworkManager.instance.meshNetwork!
        let group = network.groups[indexPath.row]
        return group.isUsed ? .none : .delete
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let network = MeshNetworkManager.instance.meshNetwork!
        let group = network.groups[indexPath.row]
        if group.isUsed {
            return [UITableViewRowAction(style: .normal, title: "In Use", handler: { _,_ in })]
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let network = MeshNetworkManager.instance.meshNetwork!
        let group = network.groups[indexPath.row]
        do {
            try network.remove(group: group)
            
            if MeshNetworkManager.instance.save() {
                tableView.deleteRows(at: [indexPath], with: .fade)
                if network.groups.isEmpty {
                    showEmptyView()
                }
            } else {
                presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
            }
        } catch {
            
        }
    }

}

extension GroupsViewController: AddGroupDelegate {
    
    func groupAdded() {
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        tableView.insertRows(at: [IndexPath(row: meshNetwork.groups.count - 1, section: 0)], with: .automatic)
        hideEmptyView()
    }
    
}
