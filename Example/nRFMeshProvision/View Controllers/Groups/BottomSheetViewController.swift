//
//  BottomSheetViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 29/08/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class BottomSheetViewController: UITableViewController {
    
    // MARK: - Outlets and Actions
    
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    // MARK: - Properties

    var models: [Model]!

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "item", for: indexPath)
        let model = models[indexPath.row]
        let element = model.parentElement!
        cell.textLabel?.text = "\(model.parentElement.name ?? "Element \(element.index + 1)")"
        cell.detailTextLabel?.text = "\(element.parentNode!.name ?? "Unknown node")"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
