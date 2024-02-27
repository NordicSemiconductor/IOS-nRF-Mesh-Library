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

class GroupsViewController: UITableViewController, Editable, UISearchBarDelegate {
    private var groups: [Group] = []
        
    // MARK: - Search Bar
    
    private var searchController: UISearchController!
    private var filteredGroups: [Group] = []
    
    // MARK: - Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEmptyView(title: "No Groups",
                               message: "Click + to create one.",
                               messageImage: #imageLiteral(resourceName: "baseline-groups"))
        createSearchBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
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
    
    // MARK: - Search Bar Delegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applyFilter(searchText)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        applyFilter("")
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredGroups.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "group", for: indexPath) as! GroupCell
        cell.group = filteredGroups[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let group = filteredGroups[indexPath.row]
        return group.isUsed ? .none : .delete
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let group = filteredGroups[indexPath.row]
        if group.isUsed {
            return UISwipeActionsConfiguration(actions: [
                UIContextualAction(style: .normal, title: "In Use", handler: { _, _, completionHandler in
                    completionHandler(false)
                })
            ])
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let network = MeshNetworkManager.instance.meshNetwork!
        let group = filteredGroups[indexPath.row]
        do {
            try network.remove(group: group)
            if let index = groups.firstIndex(of: group) {
                groups.remove(at: index)
            }
            filteredGroups.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            if filteredGroups.isEmpty {
                showEmptyView()
            }
            
            if !MeshNetworkManager.instance.save() {
                presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
            }
        } catch {
            presentAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
}

private extension GroupsViewController {
    
    func createSearchBar() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "Name, Group Address"
        searchController.searchBar.delegate = self
        searchController.searchBar.isTranslucent = false
        if #available(iOS 13.0, *) {
            searchController.searchBar.searchTextField.tintColor = .label
            searchController.searchBar.searchTextField.backgroundColor = .systemBackground
        }
        navigationItem.searchController = searchController
    }
    
    func applyFilter(_ searchText: String) {
        if searchText.isEmpty {
            filteredGroups = groups
        } else {
            filteredGroups = groups.filter {
                $0.name.lowercased().contains(searchText.lowercased()) ||
                $0.address.asString().lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
        
        if filteredGroups.isEmpty {
            showEmptyView()
        } else {
            hideEmptyView()
        }
    }
    
    func reloadData() {
        if let network = MeshNetworkManager.instance.meshNetwork {
            groups = network.groups
        }
        applyFilter(searchController.searchBar.text ?? "")
    }
    
}

extension GroupsViewController: GroupDelegate {
    
    func groupChanged(_ group: Group) {
        groups.append(group)
        filteredGroups.append(group)
        tableView.insertRows(at: [IndexPath(row: groups.count - 1, section: 0)], with: .automatic)
        hideEmptyView()
    }
    
}

