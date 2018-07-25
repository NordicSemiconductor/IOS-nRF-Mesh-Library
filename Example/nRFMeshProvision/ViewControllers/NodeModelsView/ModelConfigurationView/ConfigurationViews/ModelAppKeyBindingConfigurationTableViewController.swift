//
//  ModelAppKeyBindingConfigurationTableViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 17/04/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class ModelAppKeyBindingConfigurationTableViewController: UITableViewController {

    // MARK: - Properties
    private var stateManager: MeshStateManager!
    private var selectionDelegate: ModelConfigurationTableViewController!

    // MARK: - Implementation
    public func setSelectionDelegate(_ adelegate: ModelConfigurationTableViewController) {
        selectionDelegate = adelegate
    }

    public func setStateManager(_ aStateManager: MeshStateManager) {
        stateManager = aStateManager
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Available AppKeys"
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectionDelegate.didSelectAppKeyAtIndex(UInt16(indexPath.row))
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stateManager.state().appKeys.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCell(withIdentifier: "AppKeyBindCell", for: indexPath)
        let appKeyDictionary = stateManager.state().appKeys[indexPath.row]
        aCell.textLabel?.text = appKeyDictionary.keys.first!
        aCell.detailTextLabel?.text = "0x\(appKeyDictionary.values.first!.hexString())"
        return aCell
    }
}
