//
//  MeshConfigurationTableViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 16/01/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision
import CoreBluetooth

class MeshProvisioningDataTableViewController: UITableViewController, UITextFieldDelegate {

    // MARK: - Outlets and Actions
    @IBAction func provisioningButtonTapped(_ sender: Any) {
        handleProvisioningButtonTapped()
    }
    @IBOutlet weak var nodeNameCell: UITableViewCell!
    @IBOutlet weak var unicastAddressCell: UITableViewCell!
    @IBOutlet weak var appKeyCell: UITableViewCell!

    // MARK: - Properties
    var meshStateManager: MeshStateManager!
    var targetNode: UnprovisionedMeshNode!
    var centralManager: CBCentralManager!
    var nodeName: String! = "Mesh Node"
    var nodeAddress: Data!
    var appKeyName: String!
    var appKeyData: Data!
    var appKeyIndex: Data!

    // MARK: - UIViewController implementation
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if appKeyName == nil {
            updateProvisioningDataUI()
        }
    }

    // MARK: - Implementaiton
    private func updateProvisioningDataUI() {
        //Set the unicast according to the state
        nodeAddress = meshStateManager.state().nextUnicast
        //Update provisioning Data UI with default values
        unicastAddressCell.detailTextLabel?.text = "0x\(nodeAddress.hexString())"
        nodeNameCell.detailTextLabel?.text = nodeName
        //Select first key by default
        didSelectAppKeyWithIndex(0)
    }

    public func setMeshState(_ aStateManager: MeshStateManager) {
        meshStateManager = aStateManager
    }

    public func setTargetNode(_ aNode: UnprovisionedMeshNode, andCentralManager aCentralManager: CBCentralManager) {
        targetNode      = aNode
        centralManager  = aCentralManager
    }

    func handleProvisioningButtonTapped() {
        self.performSegue(withIdentifier: "showProvisioningView", sender: nil)
    }

    func didSelectUnicastAddressCell() {
        presentInputViewWithTitle("Please enter Unicast Address",
                                  message: "2 Bytes, > 0x0000",
                                  placeholder: self.nodeAddress.hexString()) { (anAddress) -> Void in
                                    if let anAddress = anAddress {
                                        if anAddress.count == 4 {
                                            if anAddress == "0000" ||
                                                anAddress == String(data: self.meshStateManager.state().unicastAddress,
                                                                    encoding: .utf8) {
                                                print("Adderss cannot be 0x0000, minimum possible address is 0x0001")
                                            } else {
                                                self.nodeAddress = Data(hexString: anAddress)
                                                let readableName = "0x\(self.nodeAddress.hexString())"
                                                self.unicastAddressCell.detailTextLabel?.text = readableName
                                            }
                                        } else {
                                            print("Unicast address must be exactly 2 bytes")
                                        }
                                    }
        }
    }

    func didSelectNodeNameCell() {
        presentInputViewWithTitle("Please enter a name",
                                  message: "max 20 characters",
                                  placeholder: "New Node") { (aName) -> Void in
                                    if let aName = aName {
                                        if aName.count <= 20 {
                                            self.nodeName = aName
                                            self.nodeNameCell.detailTextLabel?.text = aName
                                        } else {
                                            print("Name cannot be longer than 20 characters")
                                        }
                                    }
        }
    }

    func didSelectAppkeyCell() {
        self.performSegue(withIdentifier: "showAppKeySelector", sender: nil)
    }

    func didSelectAppKeyWithIndex(_ anIndex: Int) {
        let appKey = self.meshStateManager.state().appKeys[anIndex]
        appKeyName = appKey.keys.first
        appKeyData = appKey.values.first
        let anAppKeyIndex = UInt16(anIndex)
        appKeyIndex = Data([UInt8((anAppKeyIndex & 0xFF00) >> 8), UInt8(anAppKeyIndex & 0x00FF)])
        appKeyCell.textLabel?.text = appKeyName
        appKeyCell.detailTextLabel?.text = "0x\(appKeyData!.hexString())"
    }

    // MARK: - Input Alert
    func presentInputViewWithTitle(_ aTitle: String,
                                   message aMessage: String,
                                   placeholder aPlaceholder: String?,
                                   andCompletionHandler aHandler : @escaping (String?) -> Void) {
        let inputAlertView = UIAlertController(title: aTitle, message: aMessage, preferredStyle: .alert)
        inputAlertView.addTextField { (aTextField) in
            aTextField.keyboardType = UIKeyboardType.asciiCapable
            aTextField.returnKeyType = .done
            aTextField.delegate = self
            //Show clear button button when user is not editing
            aTextField.clearButtonMode = UITextFieldViewMode.whileEditing
            if let aPlaceholder = aPlaceholder {
                aTextField.text = aPlaceholder
            }
        }

        let saveAction = UIAlertAction(title: "Save", style: .default) { (_) in
            DispatchQueue.main.async {
                if let text = inputAlertView.textFields![0].text {
                    if text.count > 0 {
                        aHandler(text.uppercased())
                    }
                }
            }
        }

        let cancelACtion = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            DispatchQueue.main.async {
                aHandler(nil)
            }
        }

        inputAlertView.addAction(saveAction)
        inputAlertView.addAction(cancelACtion)
        present(inputAlertView, animated: true, completion: nil)
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if range.length > 0 {
            //Going backwards, always allow deletion
            return true
        } else {
            let value = string.data(using: .utf8)![0]
            //Only allow HexaDecimal values 0->9, a->f and A->F
            return (value >= 48 && value <= 57) || (value >= 65 && value <= 70) || (value >= 97 && value <= 102)
        }
   }

    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            didSelectNodeNameCell()
        case 1:
            didSelectUnicastAddressCell()
        case 2:
            didSelectAppkeyCell()
        default:
            break
        }
    }

    // MARK: - Segue and flow
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        guard  nodeAddress != nil && nodeName != nil && meshStateManager != nil else {
            print("Provisioning data not ready.")
            return false
        }
        if identifier == "showProvisioningView" {
            return true
        } else if identifier == "showAppKeySelector" {
            return true
        } else {
            return false
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAppKeySelector" {
            if let destinationView = segue.destination as? AppKeySelectorTableViewController {
                destinationView.setSelectionCallback({ (appKeyIndex) in
                    self.didSelectAppKeyWithIndex(appKeyIndex)
                }, andMeshStateManager: meshStateManager)
            }
        } else if segue.identifier == "showProvisioningView" {
            if let destinationView = segue.destination as? MeshNodeViewController {
                let provisioningData = ProvisioningData(netKey: Data(),
                                                        keyIndex: Data(),
                                                        flags: Data(),
                                                        ivIndex: Data(),
                                                        unicastAddress: nodeAddress)
                destinationView.setMeshStateManager(meshStateManager)
                destinationView.setProvisioningData(provisioningData)
                destinationView.setConfigurationData(withAppKeyData: appKeyData,
                                                     appKeyIndex: appKeyIndex,
                                                     andNetKeyIndex: meshStateManager.state().keyIndex)
                destinationView.setTargetNode(targetNode, andCentralManager: centralManager)
            }
        }
    }
}
