//
//  NodeModelsTableViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 16/04/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class NodeModelsTableViewController: UITableViewController {
    // MARK: - Properties
    private var nodeEntry: MeshNodeEntry!
    private var selectedModel: Data!
    private var meshStateManager: MeshStateManager!
    private var proxyNode: ProvisionedMeshNode!
    
    // MARK: - Implementation
    public func setProxyNode(_ aNode: ProvisionedMeshNode) {
        proxyNode = aNode
    }

    public func setMeshStateManager(_ aManager: MeshStateManager) {
        meshStateManager = aManager
    }

    public func setNodeEntry(_ aNodeEntry: MeshNodeEntry) {
        nodeEntry = aNodeEntry
    }

    // MARK: - TableViewController DataSource & Delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        if let elementCount = nodeEntry.elements?.count {
            return elementCount
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let anElement = nodeEntry.elements![section]
        return anElement.totalModelCount()
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Element \(section)"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MeshModelEntryCell", for: indexPath)
        // Configure the cell...
        let aModel = nodeEntry.elements![indexPath.section].allSigAndVendorModels()[indexPath.row]
        if aModel.count == 2 {
            cell.detailTextLabel?.text = "SIG Model"
            let upperInt = UInt16(aModel[0]) << 8
            let lowerInt = UInt16(aModel[1])
            if let modelIdentifier = MeshModelIdentifiers(rawValue: upperInt | lowerInt) {
                let modelString = MeshModelIdentifierStringConverter().stringValueForIdentifier(modelIdentifier)
                cell.textLabel?.text = modelString
            } else {
                cell.textLabel?.text = aModel.hexString()
            }
        } else {
            let vendorCompanyData = Data(aModel[0...1])
            let vendorModelId     = Data(aModel[2...3])
            var vendorModelInt    =  UInt32(0)
            vendorModelInt |= UInt32(aModel[0]) << 24
            vendorModelInt |= UInt32(aModel[1]) << 16
            vendorModelInt |= UInt32(aModel[2]) << 8
            vendorModelInt |= UInt32(aModel[3])
            cell.detailTextLabel?.text = "Vendor Model"
            if let vendorModelIdentifier = MeshVendorModelIdentifiers(rawValue: vendorModelInt) {
                let vendorModelString = MeshVendorModelIdentifierStringConverter().stringValueForIdentifier(vendorModelIdentifier)
                cell.textLabel?.text = vendorModelString
            } else {
                let formattedModel = "\(vendorCompanyData.hexString()):\(vendorModelId.hexString())"
                cell.textLabel?.text  = formattedModel
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.performSegue(withIdentifier: "ShowModelConfiguration", sender: indexPath)
    }

    // MARK: - Navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return identifier == "ShowModelConfiguration"
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowModelConfiguration" {
            if let indexPath = sender as? IndexPath {
                if let configurationView = segue.destination as? ModelConfigurationTableViewController {
                    configurationView.setMeshStateManager(meshStateManager)
                    configurationView.setNodeEntry(nodeEntry, withModelPath: indexPath)
                    configurationView.setProxyNode(proxyNode)
                }
            }
        }
    }
}
