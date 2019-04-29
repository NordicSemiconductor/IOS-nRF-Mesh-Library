//
//  ProvisionersViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 18/03/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision
	
class ProvisionersViewController: UITableViewController, Editable {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEmptyView(title: "No provisioners", message: "Click + to add a new one.", messageImage: #imageLiteral(resourceName: "baseline-security"))
        
        let hasProvisioners = MeshNetworkManager.instance.meshNetwork?.provisioners.count ?? 0 > 0
        if !hasProvisioners {
            showEmptyView()
        } else {
            hideEmptyView()
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
        case 0:
            // The first section contains the local Provisioner.
            return count > 0 ? 1 : 0
        case 1:
            // The second section contains other Provisioners.
            return count - 1
        default:
            // No other sections.
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            // The first section contains the local Provisioner.
            return "This Provisioner"
        case 1:
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
        cell.textLabel?.text = p.provisionerName
        if let node = node {
            cell.detailTextLabel?.text = "Unicast Address: \(node.unicastAddress.asString())"
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
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let removeRowAction = UITableViewRowAction(style: .destructive, title: "Delete", handler: { _, indexPath in
            self.removeProvisioner(at: indexPath)
        })
        return [removeRowAction]
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let count = MeshNetworkManager.instance.meshNetwork?.provisioners.count ?? 0
        return count > 1
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let fromIndex = sourceIndexPath.provisionerIndex
        let toIndex = destinationIndexPath.provisionerIndex
        
        // Make the required change in the data source.
        let network = MeshNetworkManager.instance.meshNetwork!
        network.moveProvisioner(fromIndex: fromIndex, toIndex: toIndex)
        
        // In here we have to ensure that there is only one Provisioner
        // in the first section.
        if sourceIndexPath.isOtherProvisioner && destinationIndexPath.isThisProvisioner {
            // If another Provisioner was dragged to the top, move the
            // previous one to the top of the second section.
            DispatchQueue.main.async {
                // Moving has to be enqueued, otherwise it doesn't work.
                tableView.moveRow(at: IndexPath(row: 1, section: 0), to: IndexPath(row: 0, section: 1))
            }
        } else if sourceIndexPath.isThisProvisioner && destinationIndexPath.isOtherProvisioner {
            // If the main Provisioner was moved to hte second section,
            // bring the next one on its place.
            DispatchQueue.main.async {
                // Moving has to be enqueued, otherwise it doesn't work.
                tableView.moveRow(at: IndexPath(row: 0, section: 1), to: IndexPath(row: 0, section: 0))
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if proposedDestinationIndexPath.isThisProvisioner ||
            (sourceIndexPath.isThisProvisioner && proposedDestinationIndexPath.row == 0) {
            return IndexPath(row: 0, section: 0)
        }
        return proposedDestinationIndexPath
    }
    
    
    // MARK: - View Controller
    
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
    
    private func provisioner(at indexPath: IndexPath) -> Provisioner? {
        let meshNetwork = MeshNetworkManager.instance.meshNetwork
        // There is one Provisioner in section 0. The rest are in section 1.
        return meshNetwork?.provisioners[indexPath.provisionerIndex]
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
            tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
        } else {
            tableView.insertRows(at: [IndexPath(row: count - 2, section: 1)], with: .top)
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
                IndexPath(row: 0, section: 0) :
                IndexPath(row: index - 1, section: 1)
            tableView.beginUpdates()
            tableView.reloadRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
    }
    
    private func removeProvisioner(at indexPath: IndexPath) {
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        let index = indexPath.provisionerIndex
        _ = meshNetwork.remove(provisionerAt: index)
        let provisionerCount = meshNetwork.provisioners.count
        
        tableView.beginUpdates()
        // Remove the deleted row.
        tableView.deleteRows(at: [indexPath], with: .top)
        if indexPath.isThisProvisioner && provisionerCount > 0 {
            // Bring another one as local Provisioner.
            tableView.moveRow(at: IndexPath(row: 0, section: 1), to: IndexPath(row: 0, section: 0))
        }
        if provisionerCount == 1 {
            // Remove Other Provisioners section.
            tableView.deleteSections(.otherProvisionersSection, with: .fade)
        }
        if provisionerCount == 0 {
            // Remove This Provisioner section.
            tableView.deleteSections(.thisProvisionerSection, with: .fade)
            showEmptyView()
        }
        tableView.endUpdates()
        
        if !MeshNetworkManager.instance.save() {
            presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
        }
    }
    
}

private extension IndexPath {
    
    /// Returns the Provisioner index in mesh network based on the
    /// IndexPath.
    var provisionerIndex: Int {
        return section + row
    }
    
    /// Returns whether the IndexPath points the local Provisioner.
    var isThisProvisioner: Bool {
        return section == 0
    }
    
    /// Returns whether the IndexPath point some other Provisioner.
    var isOtherProvisioner: Bool {
        return section == 1
    }
}

private extension IndexSet {
    
    static let thisProvisionerSection   = IndexSet(integer: 0)
    static let otherProvisionersSection = IndexSet(integer: 1)
    
}