//
//  GlobalAppKeyListManagerController.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 07/08/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class GlobalAppKeyListManagerController: UITableViewController, ProvisionedMeshNodeDelegate {

    var stateManager: MeshStateManager?
    var nodeEntry   : MeshNodeEntry?
    var proxyNode   : ProvisionedMeshNode?

    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBAction func editButtonTapped(_ sender: Any) {
        if tableView.isEditing {
            tableView.isEditing = false
            editButton.title = "Edit"
        } else {
            tableView.isEditing = true
            editButton.title = "Done"
        }
    }
    @IBAction func addButtonTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "showAppKeySelector", sender: nil)
    }
    public func setMeshStateManager(_ aStateManager: MeshStateManager) {
        stateManager = aStateManager
    }
    
    public func setNodeEntry(_ aNodeEntry: MeshNodeEntry) {
        nodeEntry = aNodeEntry
    }
    
    public func setProxyNode(_ aProxyNode: ProvisionedMeshNode) {
        proxyNode = aProxyNode
        proxyNode!.delegate = self
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Keys bound to network key at index \(section)"
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nodeEntry!.appKeys.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GlobalAppKeyEntryCell", for: indexPath)
        if let keyDictionary = stateManager?.state().appKeys[indexPath.row] {
            let keyName = keyDictionary.keys.first
            let keyValue = keyDictionary.values.first
            cell.textLabel?.text = "\(keyName!)"
            cell.detailTextLabel?.text = "0x\(keyValue!.hexString())"
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.proxyNode?.appKeyDelete(atIndex: Data([0x00, UInt8(indexPath.row)]), forNetKeyAtIndex: Data([0x00, 0x00]), onDestinationAddress: self.nodeEntry!.nodeUnicast!)
        }
    }

    // MARK: - Navigation
    //
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAppKeySelector" {
            let appKeySelector = segue.destination as? AppKeySelectorTableViewController
            appKeySelector?.setSelectionCallback({ (selectedIndex) in
                if let keyIndex = selectedIndex {
                    if keyIndex > self.nodeEntry!.appKeys.count - 1 {
                        //This key doesn't exist, let's add it
                        if let keyData = self.stateManager?.state().appKeys[keyIndex].values.first {
                            self.proxyNode?.appKeyAdd(keyData, atIndex: Data([0x00, UInt8(keyIndex)]), forNetKeyAtIndex: Data([0x00,0x00]), onDestinationAddress: self.nodeEntry!.nodeUnicast!)
                        } else {
                            print("AppKey out of bounds")
                        }
                    } else {
                        print("AppKey already added")
                    }
                } else {
                    print("No key selected")
                }
            }, andMeshStateManager: self.stateManager!)
        }
    }
    
    // MARK: - ProvisionedMeshNodeDelegate
    func receivedAppKeyStatusData(_ appKeyStatusData: AppKeyStatusMessage) {
        stateManager?.restoreState()
        let unicast = appKeyStatusData.sourceAddress
        if let anIndex = stateManager?.state().provisionedNodes.index(where: { $0.nodeUnicast == unicast}) {
            self.nodeEntry = stateManager?.state().provisionedNodes[anIndex]
            print("Node keys {")
            for aKey in self.nodeEntry!.appKeys {
                print("\t\tKey: \(aKey.hexString())")
            }
            print("}")
            self.tableView.reloadData()
        }
    }

    func nodeDidCompleteDiscovery(_ aNode: ProvisionedMeshNode) {}
    func nodeShouldDisconnect(_ aNode: ProvisionedMeshNode) {}
    func receivedCompositionData(_ compositionData: CompositionStatusMessage) {}
    func receivedModelAppBindStatus(_ modelAppStatusData: ModelAppBindStatusMessage) {}
    func receivedModelPublicationStatus(_ modelPublicationStatusData: ModelPublicationStatusMessage) {}
    func receivedModelSubsrciptionStatus(_ modelSubscriptionStatusData: ModelSubscriptionStatusMessage) {}
    func receivedDefaultTTLStatus(_ defaultTTLStatusData: DefaultTTLStatusMessage) {}
    func receivedNodeResetStatus(_ resetStatusData: NodeResetStatusMessage) {}
    func configurationSucceeded() {}
    //Generic Model Messages
    func receivedGenericOnOffStatusMessage(_ status: GenericOnOffStatusMessage) {}

}
