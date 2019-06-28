//
//  NetworkKeysViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 28/06/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class NodeNetworkKeysViewController: UITableViewController, Editable {
    
    // MARK: - Outlets and Actions
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    var node: Node!
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEmptyView(title: "No keys", message: "Click + to add a new key.", messageImage: #imageLiteral(resourceName: "baseline-key"))
        
        let hasNetKeys = node.networkKeys.count > 0
        if !hasNetKeys {
            showEmptyView()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let hasNetKeys = node.networkKeys.count > 0
        if hasNetKeys {
            hideEmptyView()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "add" {
            let destination = segue.destination as! UINavigationController
            let viewController = destination.topViewController as! NodeAddNetworkKeyViewController
            viewController.node = node
            viewController.delegate = self
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return node.networkKeys.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let key = node.networkKeys[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = key.name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // A Network Key may only be removed with a message signed with another Network Key.
        // This means, that the last Network Key may not be removed.
        // This method returns `true`, but below we return editing style `.none`.
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return node.networkKeys.count == 1 ? .none : .delete
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if node.networkKeys.count == 1 {
            return [UITableViewRowAction(style: .normal, title: "Last Key", handler: {_,_ in })]
        }
        return nil
    }
}

extension NodeNetworkKeysViewController: NetworkKeyDelegate {
    
    func keyAdded() {
        tableView.insertRows(at: [IndexPath(row: node.networkKeys.count - 1, section: 0)], with: .fade)
    }
    
}
