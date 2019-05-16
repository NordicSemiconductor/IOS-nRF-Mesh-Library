//
//  NetworkViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 16/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class NetworkViewController: UITableViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "provision":
            let destination = segue.destination as! UINavigationController
            let scannerViewController = destination.topViewController! as! ScannerTableViewController
            scannerViewController.delegate = self
        default:
            break
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

}

extension NetworkViewController: ProvisioningViewDelegate {
    
    func provisionerDidProvisionNewDevice(_ node: Node) {
        performSegue(withIdentifier: "configure", sender: node)
    }
    
}
