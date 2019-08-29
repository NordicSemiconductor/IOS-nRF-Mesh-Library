//
//  AddGroupViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 18/07/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

protocol AddGroupDelegate {
    func groupChanged(_ group: Group)
}

class AddGroupViewController: UITableViewController {

    // MARK: - Outlets & Actions
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        save()
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressCell: UITableViewCell!
    
    // MARK: - Properties
    
    var group: Group?
    var delegate: AddGroupDelegate?
    
    private var canModifyAddress: Bool = false
    private var name: String? {
        didSet {
            nameLabel.text = name
        }
    }
    private var address: MeshAddress? {
        didSet {
            if let address = address {
                addressCell.detailTextLabel?.text = address.asString()
                addressCell.detailTextLabel?.font = .systemFont(ofSize: address.address.isVirtual ? 14 : 17)
                doneButton.isEnabled = true
            } else {
                addressCell.detailTextLabel?.text = "Invalid address"
                doneButton.isEnabled = false
            }
        }
    }
    
    // MARK: - Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Editting a Group?
        if let group = group {
            title = "Edit Group"
            name = group.name
            address = group.address
            addressCell.accessoryType = .none
            return
        }
        // If not, let's set default values.
        if let network = MeshNetworkManager.instance.meshNetwork,
           let localProvisioner = network.localProvisioner {
            // Try assigning next available Group Address.
            if let automaticAddress = network.nextAvailableGroupAddress(for: localProvisioner) {
                name = "New Group"
                address = MeshAddress(automaticAddress)
            } else {
                // All addresses from Provisioner's range are taken.
                // A Virtual Label has to be used instead.
                name = "New Virtual Group"
                address = MeshAddress(UUID())
            }
            canModifyAddress = true
        } else {
            name = "New Group"
            addressCell.detailTextLabel?.text = "Provisioner not set"
            addressCell.accessoryType = .none
            doneButton.isEnabled = false
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath == .name || (indexPath == .address && canModifyAddress)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath == IndexPath.name {
            presentNameDialog()
        }
        if indexPath == IndexPath.address,
            let _ = MeshNetworkManager.instance.meshNetwork?.localProvisioner {
            presentGroupAddressDialog()
        }
    }

}

private extension AddGroupViewController {
    
    /// Presents a dialog to edit the Group name.
    func presentNameDialog() {
        presentTextAlert(title: "Group name", message: "E.g. Lights", text: name,
                         type: .nameRequired) { name in
                            self.name = name
        }
    }
    
    /// Presents a dialog to edit Group Address.
    func presentGroupAddressDialog() {
        let action = UIAlertAction(title: "Virtual Label", style: .default) { action in
            self.address = MeshAddress(UUID())
        }
        presentTextAlert(title: "Group address", message: "Hexadecimal value in range\nC000 - FEFF.",
                         text: address?.hex, placeHolder: "Address", type: .groupAddressRequired,
                         option: action) { text in
                            self.address = MeshAddress(hex: text)
        }
    }
    
    func save() {
        if let name = name, let address = address {
            do {
                if let group = group {
                    group.name = name
                    delegate?.groupChanged(group)
                } else {
                    let group = try Group(name: name, address: address)
                    let network = MeshNetworkManager.instance.meshNetwork!
                    try network.add(group: group)
                    
                    delegate?.groupChanged(group)
                }
                if MeshNetworkManager.instance.save() {
                    dismiss(animated: true)
                } else {
                    presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
                }
            } catch {
                switch error as! MeshModelError {
                case .invalidAddress:
                    presentAlert(title: "Error", message: "The address \(address.asString()) is not a valid group address.")
                case .groupAlreadyExists:
                    presentAlert(title: "Error", message: "Group with address \(address.asString()) already exists.")
                default:
                    presentAlert(title: "Error", message: "An error occurred.")
                }
            }
        }
    }
    
}

private extension IndexPath {
    
    static let detailsSection     = 0
    static let parentGroupSection = 1
    
    static let name    = IndexPath(row: 0, section: IndexPath.detailsSection)
    static let address = IndexPath(row: 1, section: IndexPath.detailsSection)
    
}
