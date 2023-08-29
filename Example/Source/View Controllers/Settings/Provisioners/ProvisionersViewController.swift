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
	
class ProvisionersViewController: UITableViewController, Editable {
    
    // MARK: - Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEmptyView(title: "No provisioners",
                               message: "Click + to add a new one.",
                               messageImage: #imageLiteral(resourceName: "baseline-security"))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let hasProvisioners = MeshNetworkManager.instance.meshNetwork?.provisioners.count ?? 0 > 0
        if !hasProvisioners {
            showEmptyView()
        } else {
            hideEmptyView(false)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let target = segue.destination as! UINavigationController
        let viewController = target.topViewController as! EditProvisionerViewController
        viewController.delegate = self
        
        if segue.identifier == "show" {
            let cell = sender! as! UITableViewCell
            let indexPath = tableView.indexPath(for: cell)!
            
            viewController.provisioner = provisioner(at: indexPath)
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        let count = MeshNetworkManager.instance.meshNetwork?.provisioners.count ?? 0
        return min(count, 2)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = MeshNetworkManager.instance.meshNetwork?.provisioners.count ?? 0
        
        switch section {
        case IndexPath.localProvisionerSection:
            // The first section contains the local Provisioner.
            return count > 0 ? 1 : 0
        case IndexPath.otherProvisionersSection:
            // The second section contains other Provisioners.
            return count - 1
        default:
            // No other sections.
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case IndexPath.localProvisionerSection:
            // The first section contains the local Provisioner.
            return "This Provisioner"
        case IndexPath.otherProvisionersSection:
            // The second section contains other Provisioners.
            return "Other Provisioners"
        default:
            // No other sections.
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "provisionerCell", for: indexPath)

        let network = MeshNetworkManager.instance.meshNetwork!
        let p = provisioner(at: indexPath)!
        let node = network.node(for: p)
        cell.textLabel?.text = p.name
        if let node = node {
            cell.detailTextLabel?.text = "Unicast Address: \(node.primaryUnicastAddress.asString())"
        } else {
            cell.detailTextLabel?.text = "Configuration capabilities disabled"
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // It is not possible to remove the last Provisioner. At least 1 is required.
        let count = MeshNetworkManager.instance.meshNetwork?.provisioners.count ?? 0
        guard count > 1 else {
            return UISwipeActionsConfiguration(actions: [
                UIContextualAction(style: .normal, title: "Last", handler: { _, _, completionHandler in
                    completionHandler(false)
                })
            ])
        }
        return UISwipeActionsConfiguration(actions: [
            UIContextualAction(style: .destructive, title: "Delete", handler: { _, _, completionHandler in
                self.removeProvisioner(at: indexPath)
                completionHandler(true)
            })
        ])
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let count = MeshNetworkManager.instance.meshNetwork?.provisioners.count ?? 0
        return count > 1
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let fromIndex = sourceIndexPath.provisionerIndex
        let toIndex = destinationIndexPath.provisionerIndex
        
        let manager = MeshNetworkManager.instance
        let network = manager.meshNetwork!
        
        // If the local Provisioner is changing, and the Proxy Filter was set to a whitelist,
        // reset the filter.
        if sourceIndexPath.isThisProvisioner || destinationIndexPath.isThisProvisioner,
           let previousLocalProvisioner = network.localProvisioner,
           previousLocalProvisioner.hasConfigurationCapabilities &&
           manager.proxyFilter.type == .acceptList {
            manager.proxyFilter.reset()
        }
        // Make the required change in the data source.
        network.moveProvisioner(fromIndex: fromIndex, toIndex: toIndex)
        if !manager.save() {
            presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
        }
        
        // In here we have to ensure that there is only one Provisioner
        // in the first section.
        if sourceIndexPath.isOtherProvisioner && destinationIndexPath.isThisProvisioner {
            // If another Provisioner was dragged to the top, move the
            // previous one to the top of the second section.
            DispatchQueue.main.async {
                // Moving has to be enqueued, otherwise it doesn't work.
                tableView.moveRow(at: IndexPath(row: 1, section: IndexPath.localProvisionerSection), to: IndexPath(otherAtRow: 0))
            }
            
        } else if sourceIndexPath.isThisProvisioner && destinationIndexPath.isOtherProvisioner {
            // If the main Provisioner was moved to hte second section,
            // bring the next one on its place.
            DispatchQueue.main.async {
                // Moving has to be enqueued, otherwise it doesn't work.
                tableView.moveRow(at: IndexPath(otherAtRow: 0), to: .localProvisioner)
            }
        }
        
        // Update the Proxy Filter after the local Provisioner has changed.
        if sourceIndexPath.isThisProvisioner || destinationIndexPath.isThisProvisioner,
           let newLocalProvisioner = network.localProvisioner,
           manager.proxyFilter.type == .acceptList {
            manager.proxyFilter.setup(for: newLocalProvisioner)
        }
    }
    
    override func tableView(_ tableView: UITableView,
                            targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
                            toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        // This method ensures that only 1 device can be put to
        // the first section. It allows placing the Provisioner as a
        // first item in section 0, or after the first one in the
        // second section.
        if proposedDestinationIndexPath.isThisProvisioner ||
            (sourceIndexPath.isThisProvisioner && proposedDestinationIndexPath.row == 0) {
            return .localProvisioner
        }
        return proposedDestinationIndexPath
    }
}

// MARK: - Private API

private extension ProvisionersViewController {
    
    func provisioner(at indexPath: IndexPath) -> Provisioner? {
        let meshNetwork = MeshNetworkManager.instance.meshNetwork
        // There is one Provisioner in section 0. The rest are in section 1.
        return meshNetwork?.provisioners[indexPath.provisionerIndex]
    }
    
    func removeProvisioner(at indexPath: IndexPath) {
        let manager = MeshNetworkManager.instance
        let meshNetwork = manager.meshNetwork!
        
        // If this Provisioner has been removed and the Proxy Filter
        // type was `.acceptList`, clear the Proxy Filter.
        // Exclusion filter must have been set up by the user, so don't
        // modify it.
        if indexPath.isThisProvisioner && manager.proxyFilter.type == .acceptList {
            manager.proxyFilter.reset()
        }
        
        // Remove the Provisioner and its Node from the network configuration.
        let index = indexPath.provisionerIndex
        _ = try? meshNetwork.remove(provisionerAt: index)
        let provisionerCount = meshNetwork.provisioners.count
        
        // If another Provisioner became the local one, and the current Proxy
        // Filter type is a whitelist, set up the Proxy Filter with all
        // addresses the new Provisioner is subscribed to.
        if indexPath.isThisProvisioner,
           let newLocalProvisioner = meshNetwork.localProvisioner,
           manager.proxyFilter.type == .acceptList {
            manager.proxyFilter.setup(for: newLocalProvisioner)
        }
        
        tableView.beginUpdates()
        // Remove the deleted row.
        tableView.deleteRows(at: [indexPath], with: .top)
        if indexPath.isThisProvisioner && provisionerCount > 0 {
            // Bring another one as local Provisioner.
            tableView.moveRow(at: IndexPath(otherAtRow: 0), to: .localProvisioner)
        }
        if provisionerCount == 1 {
            // Remove Other Provisioners section.
            tableView.deleteSections(.otherProvisionersSection, with: .fade)
        }
        if provisionerCount == 0 {
            // Remove Local Provisioner section.
            tableView.deleteSections(.localProvisionerSection, with: .fade)
            showEmptyView()
        }
        tableView.endUpdates()
        
        if !manager.save() {
            presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
        }
    }
    
}

// MARK: - EditProvisionerDelegate

extension ProvisionersViewController: EditProvisionerDelegate {
    
    func provisionerWasAdded(_ provisioner: Provisioner) {
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        let count = meshNetwork.provisioners.count
        
        tableView.beginUpdates()
        if count <= 2 {
            // Insert the first or second section.
            tableView.insertSections(IndexSet(integer: count - 1), with: .fade)
        }
        if count == 1 {
            tableView.insertRows(at: [.localProvisioner], with: .top)
        } else {
            tableView.insertRows(at: [IndexPath(otherAtRow: count - 2)], with: .top)
        }
        tableView.endUpdates()
        hideEmptyView()
    }
    
    func provisionerWasModified(_ provisioner: Provisioner) {
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        let provisioners = meshNetwork.provisioners
        let index = provisioners.firstIndex(of: provisioner)
        
        if let index = index {
            let indexPath = index == 0 ?
                IndexPath.localProvisioner :
                IndexPath(otherAtRow: index - 1)
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }
    
}

private extension IndexPath {
    static let localProvisionerSection  = 0
    static let otherProvisionersSection = 1
    
    static let localProvisioner = IndexPath(row: 0, section: IndexPath.localProvisionerSection)
    
    /// Returns the Provisioner index in mesh network based on the
    /// IndexPath.
    var provisionerIndex: Int {
        return section + row
    }
    
    /// Returns whether the IndexPath points the local Provisioner.
    var isThisProvisioner: Bool {
        return section == IndexPath.localProvisionerSection
    }
    
    /// Returns whether the IndexPath point some other Provisioner.
    var isOtherProvisioner: Bool {
        return section == IndexPath.otherProvisionersSection
    }
    
    init(otherAtRow: Int) {
        self.init(row: otherAtRow, section: IndexPath.otherProvisionersSection)
    }
    
}

private extension IndexSet {
    
    static let localProvisionerSection   = IndexSet(integer: IndexPath.localProvisionerSection)
    static let otherProvisionersSection = IndexSet(integer: IndexPath.otherProvisionersSection)
    
}
