//
//  EditProvisionerViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 04/04/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

protocol EditProvisionerDelegate {
    /// Adds the Provisioner to mesh network.
    func addProvisioner(_ provisioner: Provisioner) throws
    /// Notifies the delegate that the given provisioner was modified.
    func provisionerWasModified(_ provisioner: Provisioner)
}

class EditProvisionerViewController: UITableViewController {

    @IBOutlet weak var name: UITableViewCell!
    @IBOutlet weak var unicastAddress: UITableViewCell!
    @IBOutlet weak var unicastAddressRange: UITableViewCell!
    @IBOutlet weak var groupAddressRange: UITableViewCell!
    @IBOutlet weak var sceneRange: UITableViewCell!
    
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        saveProvisioner()
    }
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    /// The Provisioner to edit or `nil` if a new one is created.
    var provisioner: Provisioner!
    /// The delegate will be informed when the Done button is clicked.
    var delegate: EditProvisionerDelegate?
    /// A flag indicating whether the user edits or adds a new Provisioner.
    var adding = false

    override func viewDidLoad() {
        if provisioner == nil {
            provisioner = Provisioner(name: "New Provisioner")
            adding = true
        }
        
        // Show Provisioner's parameters.
        title = provisioner.provisionerName
        name.detailTextLabel?.text = provisioner.provisionerName
        
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        
        // A Provisioner does not need to have an associated node.
        // A Provisioner without a node can't perform nodes configuration operations.
        let node = meshNetwork.node(for: provisioner)
        if let node = node {
            unicastAddress.detailTextLabel?.text = node.unicastAddress.asString()
        }
        
        unicastAddressRange.detailTextLabel?.text = provisioner.allocatedUnicastRange.asString()
        groupAddressRange.detailTextLabel?.text = provisioner.allocatedGroupRange.asString()
        sceneRange.detailTextLabel?.text = provisioner.allocatedSceneRange.asString()
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                presentTextAlert(title: "Provisioner name", message: nil,
                                 text: title, placeHolder: "Name", type: .nameRequired) { newName in
                                    self.provisioner.provisionerName = newName
                                    self.name.detailTextLabel?.text = newName
                                    self.title = newName
                }
            case 1:
                let node = meshNetwork.node(for: provisioner)
                let address = node?.unicastAddress.hex ?? ""
                presentTextAlert(title: "Unicast address", message: "Hexadecimal value in range\n0001 - 7FFF.",
                                 text: address, placeHolder: "Address", type: .unicastAddressRequired) { text in
                                    let address = Address(text, radix: 16)
                                    self.unicastAddress.detailTextLabel?.text = address!.asString()
                }
            default:
                // Not possible.
                break;
            }
        case 1:
            // A segue will be performed.
            break
        case 2:
            switch indexPath.row {
            case 0:
                confirm(title: "Removing configuration capabilities", message: "The Provisioner will not be able to perform configuration operations. This can be reverted by assigning a unicast address.") { _ in
                    self.unicastAddress.detailTextLabel?.text = "Not assigned"
                }
            case 1:
                break
            default:
                // No more options.
                break
            }
        default:
            // No more sections.
            break
        }
    }
    
    /// Saves the edited or new Provisioner and pops the view contoller if saving
    /// succeeded.
    private func saveProvisioner() {
        if adding {
            do {
                try delegate?.addProvisioner(provisioner)
            } catch {
                print(error)
                
                switch error as! MeshModelError {
                case .nodeAlreadyExist:
                    presentAlert(title: "Error", message: "A node with given unicast address already exists.")
                case .overlappingProvisionerRanges:
                    presentAlert(title: "Error", message: "Provisioner's ranges overlap with another Provisioner.")
                default:
                    presentAlert(title: "Error", message: "An error occurred.")
                }
                return
            }
        } else {
            delegate?.provisionerWasModified(provisioner)
        }
        
        if MeshNetworkManager.instance.save() {
            dismiss(animated: true)
        } else {
            presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
        }
    }
}
