/*
* Copyright (c) 2023, Nordic Semiconductor
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

class SelectGroupsViewController: UITableViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var nextButton: UIBarButtonItem!
    
    // MARK: - Public properties
    
    var node: Node!
    
    // MARK: - Private properties
    
    private var selectedGroups: [Group] = []
    
    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let manager = MeshNetworkManager.instance
        let allGroups = manager.meshNetwork?.groups
        
        if let first = allGroups?.first {
            selectedGroups.append(first)
        }
        nextButton.isEnabled = !selectedGroups.isEmpty
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "next" {
            let destination = segue.destination as! SelectModelsForSubscriptionViewController
            destination.node = node
            destination.selectedGroups = selectedGroups.sorted { $0.address.address < $1.address.address }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return IndexPath.numberOfSection
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case IndexPath.infoSection:
            return 0
        default:
            let manager = MeshNetworkManager.instance
            let network = manager.meshNetwork!
            return network.groups.count + 1 // Add Group
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case IndexPath.groupsSection:
            return "Groups"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case IndexPath.infoSection:
            return "Select Groups to subscribe Models to."
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let manager = MeshNetworkManager.instance
        let network = manager.meshNetwork!
        let groups = network.groups
        
        if indexPath.row < groups.count {
            let group = groups[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "group", for: indexPath)
            cell.textLabel?.text = group.name
            cell.accessoryType = selectedGroups.contains(group) ? .checkmark : .none
            return cell
        } else {
            return tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let manager = MeshNetworkManager.instance
        let network = manager.meshNetwork!
        let groups = network.groups
        
        if indexPath.row < groups.count {
            let selectedGroup = groups[indexPath.row]
            if let index = selectedGroups.firstIndex(of: selectedGroup) {
                selectedGroups.remove(at: index)
            } else {
                selectedGroups.append(selectedGroup)
            }
            tableView.reloadRows(at: [indexPath], with: .automatic)
        } else {
            let index = network.groups.count + 1
            if let address = network.nextAvailableGroupAddress(),
               let newGroup = try? Group(name: "Group \(index)", address: address) {
                try! network.add(group: newGroup)
                _ = manager.save()
                selectedGroups.append(newGroup)
                tableView.insertRows(at: [indexPath], with: .automatic)
            }
        }
        nextButton.isEnabled = !selectedGroups.isEmpty
    }

}

private extension IndexPath {
    static let infoSection     = 0
    static let groupsSection   = 1
    static let numberOfSection = IndexPath.groupsSection + 1
}
