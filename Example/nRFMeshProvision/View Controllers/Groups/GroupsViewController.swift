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

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

}

extension GroupsViewController: AddGroupDelegate {
    
    func groupAdded() {
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        tableView.insertRows(at: [IndexPath(row: meshNetwork.groups.count - 1, section: 0)], with: .automatic)
        hideEmptyView()
    }
    
}
