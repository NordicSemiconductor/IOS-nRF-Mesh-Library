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
    /// Notifies the delegate that the Provisioner was added to the mesh network.
    ///
    /// - parameter provisioner: The new Provisioner.
    func provisionerWasAdded(_ provisioner: Provisioner)
    /// Notifies the delegate that the given provisioner was modified.
    ///
    /// - parameter provisioner: The Provisioner that has been modified.
    func provisionerWasModified(_ provisioner: Provisioner)
}

class EditProvisionerViewController: UITableViewController {

    @IBOutlet weak var name: UITableViewCell!
    @IBOutlet weak var unicastAddress: UITableViewCell!
    @IBOutlet weak var unicastAddressRange: RangeView!
    @IBOutlet weak var groupAddressRange: RangeView!
    @IBOutlet weak var sceneRange: RangeView!
    
    @IBOutlet weak var disableConfigCell: UITableViewCell!
    @IBOutlet weak var useThisProvisionerCell: UITableViewCell!
    
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
    
    var newName: String? = nil
    var newAddress: Address? = nil
    var disableConfigCapabilities: Bool = false

    override func viewDidLoad() {
        if provisioner == nil {
            provisioner = Provisioner(name: UIDevice.current.name)
            adding = true
            title = "New Provisioner"
        } else {
            title = "Edit Provisioner"
        }
        
        // Show Provisioner's parameters.
        name.detailTextLabel?.text = provisioner.provisionerName
        
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        
        // A Provisioner does not need to have an associated node.
        // A Provisioner without a node can't perform nodes configuration operations.
        let node = meshNetwork.node(for: provisioner)
        if let node = node {
            unicastAddress.detailTextLabel?.text = node.unicastAddress.asString()
        }
        
        // Draw ranges for the Provisioner.
        unicastAddressRange.addRanges(provisioner.allocatedUnicastRange)
        groupAddressRange.addRanges(provisioner.allocatedGroupRange)
        sceneRange.addRanges(provisioner.allocatedSceneRange)
        // Also, draw ranges of other Provisioners.
        meshNetwork.provisioners.filter({ $0 != provisioner }).forEach {
            unicastAddressRange.addOtherRanges($0.allocatedUnicastRange)
            groupAddressRange.addOtherRanges($0.allocatedGroupRange)
            sceneRange.addOtherRanges($0.allocatedSceneRange)
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        
        switch indexPath.section {
        case 0: // Provisioner data
            switch indexPath.row {
            case 0: // Provisioner name
                presentTextAlert(title: "Provisioner name", message: nil,
                                 text: provisioner.provisionerName, placeHolder: "Name",
                                 type: .nameRequired) { newName in
                                    self.newName = newName
                                    self.name.detailTextLabel?.text = newName
                                    self.title = newName
                }
            case 1: // Unicast Address
                let node = meshNetwork.node(for: provisioner)
                let address = node?.unicastAddress.hex ?? ""
                
                // If node has been assigned, add the option to unbind the node.
                let action = node == nil ? nil : UIAlertAction(title: "Unbind", style: .destructive) { action in
                    self.confirm(title: "Disable configuration capabilities",
                            message: "A Provisioner without the unicast address assigned is not able to perform configuration operations.") { _ in
                                self.disableConfigCapabilities = true
                                self.newAddress = nil
                                self.unicastAddress.detailTextLabel?.text = "Not assigned"
                    }
                }
                presentTextAlert(title: "Unicast address", message: "Hexadecimal value in range\n0001 - 7FFF.",
                                 text: address, placeHolder: "Address", type: .unicastAddressRequired,
                                 option: action) { text in
                                    let address = Address(text, radix: 16)
                                    self.unicastAddress.detailTextLabel?.text = address!.asString()
                                    self.disableConfigCapabilities = false
                                    self.newAddress = address
                }
            default:
                // Not possible.
                break;
            }
        case 1: // Allocated ranges
            // A segue will be performed.
            break
        default:
            // Not possible.
            break;
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        
        let cell = sender! as! UITableViewCell
        let indexPath = tableView.indexPath(for: cell)!
        
        switch indexPath.section {
        case 1: // Allocated ranges
            let destination = segue.destination as! EditRangesViewController
            switch indexPath.row {
            case 0: // Unicast Address
                destination.bounds = Address.minUnicastAddress...Address.maxUnicastAddress
                destination.ranges = provisioner.allocatedUnicastRange
                
                meshNetwork.provisioners.filter({ $0 != provisioner }).forEach { other in
                    destination.otherProvisionerRanges.append(contentsOf: other.allocatedUnicastRange)
                }
            case 1: // GRoup Address
                destination.bounds = Address.minGroupAddress...Address.maxGroupAddress
                destination.ranges = provisioner.allocatedGroupRange
                
                meshNetwork.provisioners.filter({ $0 != provisioner }).forEach { other in
                    destination.otherProvisionerRanges.append(contentsOf: other.allocatedGroupRange)
                }
            case 2: // Scenes
                destination.bounds = Scene.minScene...Scene.maxScene
                destination.ranges = provisioner.allocatedSceneRange
                
                meshNetwork.provisioners.filter({ $0 != provisioner }).forEach { other in
                    destination.otherProvisionerRanges.append(contentsOf: other.allocatedSceneRange)
                }
            default:
                // Not possible
                break
            }
        default:
            // Not possible
            break
        }
    }
    
    /// Saves the edited or new Provisioner and pops the view contoller if saving
    /// succeeded.
    private func saveProvisioner() {
        do {
            let meshNetwork = MeshNetworkManager.instance.meshNetwork!
            if adding {
                try meshNetwork.add(provisioner: provisioner, withAddress: newAddress)
            } else { // modifying
                if let newAddress = newAddress {
                    try meshNetwork.assign(unicastAddress: newAddress, for: provisioner)
                }
                if disableConfigCapabilities {
                    meshNetwork.disableConfigurationCapabilities(for: provisioner)
                }
            }
            if let newName = newName {
                provisioner.provisionerName = newName
            }
            // TODO ranges
            
            if adding {
                delegate?.provisionerWasAdded(provisioner)
            } else {
                delegate?.provisionerWasModified(provisioner)
            }
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
        
        if MeshNetworkManager.instance.save() {
            dismiss(animated: true)
        } else {
            presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
        }
    }
    
}
