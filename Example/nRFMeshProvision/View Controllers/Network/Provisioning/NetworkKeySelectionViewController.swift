//
//  NetworkKeySelectionViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 06/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

protocol SelectionDelegate {
    func networkKeySelected(_ networkKey: NetworkKey?)
}

class NetworkKeySelectionViewController: UITableViewController {
    
    var selectedNetworkKey: NetworkKey!
    var delegate: SelectionDelegate?
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        let count = MeshNetworkManager.instance.meshNetwork?.networkKeys.count ?? 0
        return min(count, 2)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Primary Network Key"
        default:
            return "Subnetwork Keys"
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = MeshNetworkManager.instance.meshNetwork?.networkKeys.count ?? 0
        switch section {
        case 0:
            return count > 0 ? 1 : 0
        default:
            return count - 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let network = MeshNetworkManager.instance.meshNetwork!
        let networkKey = network.networkKeys[indexPath.keyIndex]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "subtitleCell", for: indexPath)
        cell.textLabel?.text = networkKey.name
        cell.detailTextLabel?.text = networkKey.key.hex
        
        if networkKey == selectedNetworkKey {
            cell.accessoryType = .checkmark
            // Save the checked row number as tag.
            tableView.tag = indexPath.keyIndex
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let network = MeshNetworkManager.instance.meshNetwork!
        selectedNetworkKey = network.networkKeys[indexPath.keyIndex]
        delegate?.networkKeySelected(selectedNetworkKey)
        
        let row = max(tableView.tag - 1, 0)
        let section = tableView.tag > 0 ? 1 : 0
        tableView.reloadRows(at: [indexPath, IndexPath(row: row, section: section)], with: .fade)
    }

}

private extension IndexPath {
    
    /// Returns the Network Key index in mesh network based on the
    /// IndexPath.
    var keyIndex: Int {
        return section + row
    }
    
}
