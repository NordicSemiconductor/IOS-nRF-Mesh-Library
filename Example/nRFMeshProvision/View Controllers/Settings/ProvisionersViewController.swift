//
//  ProvisionersViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 18/03/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision
	
class ProvisionersViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEmptyView(title: "No provisioners", message: "Click + to add a new one.", messageImage: #imageLiteral(resourceName: "baseline-security"))
        
        let hasProvisioners = MeshNetworkManager.instance.meshNetwork?.hasProvisioners() ?? false
        if !hasProvisioners {
            showEmptyView()
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        let showMore = MeshNetworkManager.instance.meshNetwork?.hasOtherProvisioners() ?? false
        return showMore ? 2 : 1
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
            return "Provisioners"
        default:
            // No other sections.
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "provisionerCell", for: indexPath)

        let network = MeshNetworkManager.instance.meshNetwork!
        let provisioner = network.provisioners[indexPath.row]
        let node = network.node(for: provisioner)
        cell.textLabel?.text = provisioner.provisionerName
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
        return indexPath.section == 1
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let network = MeshNetworkManager.instance.meshNetwork!
        let count = network.provisioners.count
        return indexPath.section == 1 && count > 2
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            removeProvisioner(at: indexPath)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    // MARK: - View Controller
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let target = segue.destination as? UINavigationController
        let viewController = target?.topViewController as? EditProvisionerViewController
        viewController?.delegate = self
        
        if segue.identifier == "show" {
            let cell = sender! as! UITableViewCell
            let indexPath = tableView.indexPath(for: cell)!
            
            let network = MeshNetworkManager.instance.meshNetwork!
            let provisioner = network.provisioners[indexPath.row]
            
            viewController?.provisioner = provisioner
        }
    }
    
}

// MARK: - EditProvisionerDelegate

extension ProvisionersViewController: EditProvisionerDelegate {
    
    func provisionerWasAdded(_ provisioner: Provisioner) {
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        
        tableView.beginUpdates()
        if !meshNetwork.hasOtherProvisioners() {
            tableView.insertSections(IndexSet(integer: 1), with: .automatic)
        }
        tableView.insertRows(at: [IndexPath(row: meshNetwork.provisioners.count - 1, section: 0)], with: .automatic)
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
            tableView.reloadRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
        }
    }
    
    private func removeProvisioner(at indexPath: IndexPath) {
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        _ = meshNetwork.remove(provisionerAt: indexPath.row)
        
        tableView.beginUpdates()
        tableView.deleteRows(at: [indexPath], with: .automatic)
        if !meshNetwork.hasOtherProvisioners() {
            tableView.deleteSections(IndexSet(integer: 1), with: .automatic)
            showEmptyView()
        }
        tableView.endUpdates()
    }
    
}

// MARK: - Private API

private extension ProvisionersViewController {
    
    /// Shows the 'Empty View'.
    private func showEmptyView() {
        if navigationItem.rightBarButtonItems!.contains(editButtonItem) {
            navigationItem.rightBarButtonItems!.removeAll {
                $0 == self.editButtonItem
            }
        }
        tableView.showEmptyView()
    }
    
    /// Hides the 'Empty View'.
    private func hideEmptyView() {
        if !navigationItem.rightBarButtonItems!.contains(editButtonItem) {
            navigationItem.rightBarButtonItems!.append(editButtonItem)
        }
        tableView.hideEmptyView()
    }
}
