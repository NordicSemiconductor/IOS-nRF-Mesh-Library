//
//  BindAppKeyViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 26/04/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class BindAppKeyViewController: UITableViewController {
    var applicationKey: ApplicationKey!
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let network = MeshNetworkManager.instance.meshNetwork!
        return network.networkKeys.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Network Keys"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "netKeyCell", for: indexPath)
        
        let network = MeshNetworkManager.instance.meshNetwork!
        let networkKey = network.networkKeys[indexPath.row]
        cell.textLabel?.text = networkKey.name
        cell.detailTextLabel?.text = networkKey.key.hex
        
        if networkKey.index == applicationKey.boundNetKey {
            cell.accessoryType = .checkmark
            // Save the checked row number as tag.
            tableView.tag = indexPath.row
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let network = MeshNetworkManager.instance.meshNetwork!
        let networkKey = network.networkKeys[indexPath.row]
        applicationKey.bind(to: networkKey)
        
        tableView.reloadRows(at: [indexPath, IndexPath(row: tableView.tag, section: 0)], with: .fade)
        
        if !MeshNetworkManager.instance.save() {
            self.presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
        }
    }

}
