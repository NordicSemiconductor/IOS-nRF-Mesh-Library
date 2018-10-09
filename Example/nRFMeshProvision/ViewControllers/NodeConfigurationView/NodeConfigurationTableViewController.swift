//
//  NodeConfigurationTableViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 16/04/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class NodeConfigurationTableViewController: UITableViewController, ProvisionedMeshNodeDelegate {

    // MARK: - Properties
    private var nodeEntry: MeshNodeEntry!
    private var selectedModel: Data!
    private var meshManager: NRFMeshManager!
    private var proxyNode: ProvisionedMeshNode!
    
    // MARK: - Implementation
    public func setNodeEntry(_ aNodeEntry: MeshNodeEntry) {
        nodeEntry = aNodeEntry
    }

    // MARK: - UIViewController
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        meshManager = (UIApplication.shared.delegate as? AppDelegate)?.meshManager
        meshManager.stateManager().restoreState()
        proxyNode = meshManager.proxyNode()
        if let targetUnicast = nodeEntry.nodeUnicast {
            nodeEntry = meshManager.stateManager().state().provisionedNodes.first { (anEntry) -> Bool in
                return anEntry.nodeUnicast == targetUnicast
            }
        }
        tableView.reloadData()
    }

    // MARK: - TableViewController DataSource & Delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        if let elementCount = nodeEntry.elements?.count {
            return elementCount + 2 //extra rows for the node reset cell and the AppKey management cell
        }
        return 2 //node reset cell + AppKey Management Cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard nodeEntry.elements != nil else {
            print("No entries")
            return 0
        }
        if section == nodeEntry.elements!.count {
            //AppKeys management
            return 1
        } else if section == nodeEntry.elements!.count + 1 {
            //Node reset cell
            return 1
        } else {
            let anElement = nodeEntry.elements![section]
            return anElement.totalModelCount()
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard nodeEntry.elements != nil else {
            print("No entries")
            return "N/A"
        }
        if section == nodeEntry.elements!.count {
            return "Application Keys"
        } else  if section == nodeEntry.elements!.count + 1 {
            return "Node Reset"
        } else {
            let unicast = nodeEntry.nodeUnicast!
            let elementAddress = Data([unicast[0], unicast[1] + UInt8(section)])
            return "Element \(section). Unicast: \(elementAddress.hexString())"
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        guard nodeEntry.elements != nil else {
            print("No elements")
            return UITableViewCell()
        }
        if indexPath.section == nodeEntry.elements!.count {
            cell = tableView.dequeueReusableCell(withIdentifier: "MeshAppKeysCell", for: indexPath)
            cell.textLabel?.text = "Global AppKey List"
            if nodeEntry.appKeys.count == 0 {
                cell.detailTextLabel?.text = "List is empty, tap to add keys"
            } else {
                cell.detailTextLabel?.text = "\(nodeEntry.appKeys.count) Keys added"
            }
        } else if indexPath.section == nodeEntry.elements!.count + 1 {
            cell = tableView.dequeueReusableCell(withIdentifier: "MeshNodeDestructiveCell", for: indexPath)
            cell.textLabel?.text = "Reset Node"
            cell.detailTextLabel?.text = nil
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "MeshModelEntryCell", for: indexPath)
            // Configure the cell...
            let element = nodeEntry.elements![indexPath.section]
            let aModel = element.allSigAndVendorModels()[indexPath.row]
            (cell as! NodeModelCell).configureWithModel(aModel, inElement: element)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard nodeEntry.elements != nil else {
            print("No Elements")
            return
        }
        if indexPath.section == nodeEntry.elements!.count {
            self.performSegue(withIdentifier: "ShowAppKeyListManager", sender: indexPath)
        } else if indexPath.section == nodeEntry.elements!.count + 1 {
            self.presentConfirmationAlert(withBody: "This will remove the node from the network.\nThis is a non-reversible action, are you sure you want to reset this node?")
        } else {
            self.performSegue(withIdentifier: "ShowModelConfiguration", sender: indexPath)
        }
    }

    // MARK: - Alert view helpers
    func presentConfirmationAlert(withBody aBody: String) {
        let confirmationAlertView = UIAlertController(title: "Warning",
                                                      message: aBody,
                                                      preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { (_) in
            DispatchQueue.main.async {
                self.proxyNode.delegate = self
                self.proxyNode.resetNode(destinationAddress: self.nodeEntry.nodeUnicast!)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            self.dismiss(animated: true)
        }
        
        confirmationAlertView.addAction(confirmAction)
        confirmationAlertView.addAction(cancelAction)
        present(confirmationAlertView, animated: true, completion: nil)
    }

    // MARK: - ProvisionedMeshNodeDelegate
    func receivedGenericLevelStatusMessage(_ status: GenericLevelStatusMessage) {
        print("Level status = \(status.levelStatus)")
    }
    func receivedGenericOnOffStatusMessage(_ status: GenericOnOffStatusMessage) {
        print("OnOff status = \(status.onOffStatus)")
    }

    func nodeDidCompleteDiscovery(_ aNode: ProvisionedMeshNode) {
        //NOOP
    }

    func nodeShouldDisconnect(_ aNode: ProvisionedMeshNode) {
        //NOOP
    }

    func receivedCompositionData(_ compositionData: CompositionStatusMessage) {
        //NOOP
    }

    func receivedAppKeyStatusData(_ appKeyStatusData: AppKeyStatusMessage) {
        //NOOP
    }

    func receivedModelAppStatus(_ modelAppStatusData: ModelAppStatusMessage) {
        //NOOP
    }

    func receivedModelPublicationStatus(_ modelPublicationStatusData: ModelPublicationStatusMessage) {
        //NOOP
    }

    func receivedModelSubsrciptionStatus(_ modelSubscriptionStatusData: ModelSubscriptionStatusMessage) {
        //NOOP
    }

    func receivedDefaultTTLStatus(_ defaultTTLStatusData: DefaultTTLStatusMessage) {
        //NOOP
    }

    func receivedNodeResetStatus(_ resetStatusData: NodeResetStatusMessage) {
        var provisionedNodes = meshManager.stateManager().state().provisionedNodes
        if let nodeIndex = provisionedNodes.index(of: nodeEntry) {
            provisionedNodes.remove(at: nodeIndex)
            meshManager.stateManager().state().provisionedNodes = provisionedNodes
            meshManager.stateManager().saveState()
            self.navigationController?.popToRootViewController(animated: true)
        }
    }

    func configurationSucceeded() {
        //NOOP
    }

    // MARK: - Navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return ["ShowModelConfiguration", "ShowAppKeyListManager"].contains(identifier)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let meshStateManager = meshManager.stateManager()
        if segue.identifier == "ShowModelConfiguration" {
            if let indexPath = sender as? IndexPath {
                if let configurationView = segue.destination as? ModelConfigurationTableViewController {
                    configurationView.setMeshStateManager(meshStateManager)
                    configurationView.setNodeEntry(nodeEntry, withModelPath: indexPath)
                    configurationView.setProxyNode(proxyNode)
                }
            }
        } else if segue.identifier == "ShowAppKeyListManager" {
            print("Showing appkey list manager")
            if let appKeyListView = segue.destination as? GlobalAppKeyListManagerController {
                appKeyListView.setMeshStateManager(meshStateManager)
                appKeyListView.setNodeEntry(nodeEntry)
                appKeyListView.setProxyNode(proxyNode)
            }
        }
    }
}
