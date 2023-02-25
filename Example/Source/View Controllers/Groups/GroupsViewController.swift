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

class GroupsViewController: UITableViewController, Editable , UISearchResultsUpdating{
    
    // MARK: - search sunc
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        if !searchText.isEmpty {
            filteredGroups = MeshNetworkManager.instance.meshNetwork!.groups.filter {
                $0.name.lowercased().contains(searchText.lowercased()) ||
                $0.address.asString().lowercased().contains(searchText.lowercased())
            }
        } else {
            filteredGroups = nil
        }
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        let network = MeshNetworkManager.instance.meshNetwork!
        filteredGroups = network.groups
        tableView.reloadData()
    }
    
    let searchController = UISearchController(searchResultsController: nil)
    var filteredGroups: [Group]?
    
    
    // MARK: - Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by Group name, Group address"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        tableView.setEmptyView(title: "No Groups",
                               message: "Click + to create one.",
                               messageImage: #imageLiteral(resourceName: "baseline-groups"))
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
           if let filteredGroups = filteredGroups {
               return filteredGroups.count
           } else {
               return meshNetwork?.groups.count ?? 0
           }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "group", for: indexPath) as! GroupCell
           if let filteredGroups = filteredGroups {
               cell.group = filteredGroups[indexPath.row]
           } else {
               cell.group = MeshNetworkManager.instance.meshNetwork!.groups[indexPath.row]
           }
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
            presentAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
}

extension GroupsViewController: GroupDelegate {
    
    func groupChanged(_ group: Group) {
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        tableView.insertRows(at: [IndexPath(row: meshNetwork.groups.count - 1, section: 0)], with: .automatic)
        hideEmptyView()
    }
    
}
