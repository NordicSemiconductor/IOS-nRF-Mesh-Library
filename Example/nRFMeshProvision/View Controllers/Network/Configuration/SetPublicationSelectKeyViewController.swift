//
//  SetPublicationSelectKeyViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 03/07/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

protocol KeySelectionDelegate {
    func keySelected(_ applicationKey: ApplicationKey)
}

class SetPublicationSelectKeyViewController: UITableViewController {
    
    // MARK: - Properties
    
    var model: Model!
    var selectedKey: ApplicationKey!
    var delegate: KeySelectionDelegate?

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.boundApplicationKeys.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let key = model.boundApplicationKeys[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "key", for: indexPath)
        cell.textLabel?.text = key.name
        cell.detailTextLabel?.text = "Bound to \(key.boundNetworkKey.name)"
        cell.accessoryType = key == selectedKey ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let key = model.boundApplicationKeys[indexPath.row]
        selectedKey = key
        delegate?.keySelected(key)
        tableView.reloadData()
    }
}
