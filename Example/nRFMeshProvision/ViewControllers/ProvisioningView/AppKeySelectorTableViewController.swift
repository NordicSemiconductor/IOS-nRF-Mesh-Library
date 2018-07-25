//
//  AppKeySelectorTableViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 05/04/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class AppKeySelectorTableViewController: UITableViewController {

    // MARK: - Properties
    private var meshStateManager: MeshStateManager!
    private var selectionCallback: ((Int) -> Void)!

    // MARK: - Implementation
    public func setSelectionCallback(_ aCallback: @escaping (Int) -> Void,
                                     andMeshStateManager aStateManager: MeshStateManager) {
        meshStateManager = aStateManager
        selectionCallback = aCallback
    }

    // MARK: - Table view data source & delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectionCallback(indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
        self.navigationController?.popViewController(animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return meshStateManager.state().appKeys.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCell(withIdentifier: "AppKeySelectionCell", for: indexPath)
        let aKey = meshStateManager.state().appKeys[indexPath.row]
        let keyName = aKey.keys.first!
        let keyValue = aKey.values.first!
        aCell.textLabel?.text = keyName
        aCell.detailTextLabel?.text = "0x\(keyValue.hexString())"
        return aCell
    }
}
