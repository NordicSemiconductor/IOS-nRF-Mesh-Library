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
    /// Notifies the delegate that the given Provisioner was modified.
    ///
    /// - parameter provisioner: The Provisioner that has been modified.
    func provisionerWasModified(_ provisioner: Provisioner)
}

class EditProvisionerViewController: UITableViewController {

    // MARK: - Outlets
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var unicastAddressLabel: UILabel!
    @IBOutlet weak var ttlCell: UITableViewCell!
    @IBOutlet weak var deviceKeyCell: UITableViewCell!
    @IBOutlet weak var unicastAddressRange: RangeView!
    @IBOutlet weak var groupAddressRange: RangeView!
    @IBOutlet weak var sceneRange: RangeView!
    
    // MARK: - Actions
    
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        saveProvisioner()
    }
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    // MARK: - Public parameters
    
    /// The Provisioner to edit or `nil` if a new one is created.
    var provisioner: Provisioner!
    /// The delegate will be informed when the Done button is clicked.
    var delegate: EditProvisionerDelegate?
    /// A flag indicating whether the user edits or adds a new Provisioner.
    var adding = false
    
    // MARK: - Private fields
    
    private var newName: String? = nil
    private var newAddress: Address? = nil
    private var disableConfigCapabilities: Bool = false
    private var newTtl: UInt8? = nil
    private var newUnicastAddressRange: [AddressRange]? = nil
    private var newGroupAddressRange: [AddressRange]? = nil
    private var newSceneRange: [SceneRange]? = nil
    
    // MARK: - View Controller

    override func viewDidLoad() {
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        
        if provisioner == nil {
            // These ranges grow propotionally.
            let nextAddressRange = meshNetwork.nextAvailableUnicastAddressRange(ofSize: 0x199A)
            let nextGroupRange = meshNetwork.nextAvailableGroupAddressRange(ofSize: 0x0C9A)
            let nextSceneRange = meshNetwork.nextAvailableSceneRange(ofSize: 0x3334)
            provisioner = Provisioner(name: UIDevice.current.name,
                                      allocatedUnicastRange: [nextAddressRange ?? AddressRange.allUnicastAddresses],
                                      allocatedGroupRange: [nextGroupRange ?? AddressRange.allGroupAddresses],
                                      allocatedSceneRange: [nextSceneRange ?? SceneRange.allScenes])
            adding = true
            title = "New Provisioner"
        } else {
            title = "Edit Provisioner"
        }
        
        // Show Provisioner's parameters.
        nameLabel.text = provisioner.provisionerName
        
        // A Provisioner does not need to have an associated node.
        // A Provisioner without a node can't perform nodes configuration operations.
        let node = meshNetwork.node(for: provisioner)
        if let node = node {
            unicastAddressLabel.text = node.unicastAddress.asString()
            ttlCell.detailTextLabel?.text = "\(node.defaultTTL ?? 5)"
            ttlCell.accessoryType = .disclosureIndicator
            deviceKeyCell.detailTextLabel?.text = node.deviceKey.hex
            deviceKeyCell.detailTextLabel?.font = .systemFont(ofSize: 14)
        } else {
            ttlCell.detailTextLabel?.text = "N/A"
            ttlCell.accessoryType = .none
            deviceKeyCell.detailTextLabel?.text = "N/A"
            deviceKeyCell.detailTextLabel?.font = .systemFont(ofSize: 17)
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        
        let cell = sender! as! UITableViewCell
        let indexPath = tableView.indexPath(for: cell)!
        
        if indexPath.isAllocatedRangesSection {
            let destination = segue.destination as! EditRangesViewController
            destination.delegate = self
            
            switch indexPath.row {
            case 0: // Unicast Address
                destination.title  = "Unicast Addresses"
                destination.type   = .unicastAddress
                destination.bounds = Address.minUnicastAddress...Address.maxUnicastAddress
                destination.ranges = newUnicastAddressRange ?? provisioner.allocatedUnicastRange
                
                meshNetwork.provisioners.filter({ $0 != provisioner }).forEach { other in
                    destination.otherProvisionerRanges.append(contentsOf: other.allocatedUnicastRange)
                }
            case 1: // Group Address
                destination.title  = "Group Addresses"
                destination.type   = .groupAddress
                destination.bounds = Address.minGroupAddress...Address.maxGroupAddress
                destination.ranges = newGroupAddressRange ?? provisioner.allocatedGroupRange
                
                meshNetwork.provisioners.filter({ $0 != provisioner }).forEach { other in
                    destination.otherProvisionerRanges.append(contentsOf: other.allocatedGroupRange)
                }
            case 2: // Scenes
                destination.title  = "Scenes"
                destination.type   = .scene
                destination.bounds = Scene.minScene...Scene.maxScene
                destination.ranges = newSceneRange ?? provisioner.allocatedSceneRange
                
                meshNetwork.provisioners.filter({ $0 != provisioner }).forEach { other in
                    destination.otherProvisionerRanges.append(contentsOf: other.allocatedSceneRange)
                }
            default:
                // Not possible
                break
            }
        }
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if indexPath.isTtl {
           return newAddress != nil || (provisioner.node != nil && !disableConfigCapabilities)
        }
        if indexPath.isDeviceKey {
            return provisioner.node != nil && !disableConfigCapabilities
        }
        return true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.isProvisionerName {
            presentNameDialog()
        }
        if indexPath.isUnicastAddress {
            presentUnicastAddressDialog()
        }
        if indexPath.isTtl {
            presentTTLDialog()
        }
        if indexPath.isDeviceKey {
            if let deviceKey = provisioner.node?.deviceKey {
                UIPasteboard.general.string = deviceKey.hex
                showToast("Key copied to Clipboard.")
            }
        }
    }
    
}

private extension EditProvisionerViewController {
    
    /// Presents a dialog to edit the Provisioner name.
    func presentNameDialog() {
        presentTextAlert(title: "Provisioner name", message: nil,
                         text: newName ?? provisioner.provisionerName, placeHolder: "Name",
                         type: .nameRequired) { newName in
                            self.newName = newName
                            self.nameLabel.text = newName
        }
    }
    
    /// Presents a dialog to edit or unbind the Provisioner Unicast Address.
    func presentUnicastAddressDialog() {
        let node = provisioner.node
        let address = newAddress?.hex ?? node?.unicastAddress.hex ?? ""
        
        // If node has been assigned, add the option to unbind the node.
        let nodeAssigned = newAddress != nil || (node != nil && !disableConfigCapabilities)
        let action = !nodeAssigned ? nil : UIAlertAction(title: "Unassign", style: .destructive) { action in
            self.confirm(title: "Disable configuration capabilities",
                         message: "A Provisioner without the unicast address assigned is not able to perform configuration operations.") { _ in
                            self.disableConfigCapabilities = true
                            self.newAddress = nil
                            self.unicastAddressLabel.text = "Not assigned"
                            self.ttlCell.detailTextLabel?.text = "N/A"
                            self.ttlCell.accessoryType = .none
                            self.newTtl = nil
                            self.deviceKeyCell.detailTextLabel?.text = "N/A"
                            self.deviceKeyCell.detailTextLabel?.font = .systemFont(ofSize: 17)
            }
        }
        presentTextAlert(title: "Unicast address", message: "Hexadecimal value in range\n0001 - 7FFF.",
                         text: address, placeHolder: "Address", type: .unicastAddressRequired,
                         option: action) { text in
                            let address = Address(text, radix: 16)
                            self.unicastAddressLabel.text = address!.asString()
                            self.disableConfigCapabilities = false
                            self.newAddress = address
                            self.ttlCell.detailTextLabel?.text = "\(self.newTtl ?? self.provisioner.node?.defaultTTL ?? 5)"
                            self.ttlCell.accessoryType = .disclosureIndicator
                            // If the Node does not exist yet, the key will be generated later,
                            // after the Provisioner is saved. For the time being print Unknown.
                            if let deviceKey = self.provisioner.node?.deviceKey {
                                self.deviceKeyCell.detailTextLabel?.text = "\(deviceKey.hex)"
                                self.deviceKeyCell.detailTextLabel?.font = .systemFont(ofSize: 14)
                            } else {
                                self.deviceKeyCell.detailTextLabel?.text = "Unknown"
                                self.deviceKeyCell.detailTextLabel?.font = .systemFont(ofSize: 17)
                            }
        }
    }
    
    /// Presents a dialog to edit the default TTL.
    func presentTTLDialog() {
        let node = provisioner.node
        
        presentTextAlert(title: "Default TTL",
                         message: "TTL = Time To Live\n\nTTL limits the number of times a message can be relayed.\nMax value is 127.",
                         text: "\(node?.defaultTTL ?? 5)", placeHolder: "Default is 5",
                         type: .ttlRequired) { value in
                            let ttl = UInt8(value)!
                            self.newTtl = ttl
                            self.ttlCell.detailTextLabel?.text = "\(ttl)"
        }
     }
    
    /// Saves the edited or new Provisioner and pops the view contoller if saving
    /// succeeded.
    func saveProvisioner() {
        do {
            let meshNetwork = MeshNetworkManager.instance.meshNetwork!
            if adding {
                // Allocate new ranges, had they changed.
                try allocateNewRanges(to: provisioner)
                // And try adding the new Provisioner. This may throw number of errors.
                try meshNetwork.add(provisioner: provisioner, withAddress: newAddress)
            } else {
                // First, check if the new ranges are not overlapping other Provisioners' ranges.
                // The initial check is necessary so that we do not commit any changes before
                // we are sure everything is OK.
                try ensureNewRangesAreValid(for: provisioner)
                // Check whether the new address is within Provisioner's range.
                try ensureAddressIsValid(for: provisioner)
                // Now it's safe to allocate ranges. They must be valid, so will not throw here.
                try allocateNewRanges(to: provisioner)
                // Try assigning the new Unicast Address. Hopefully this will not throw,
                // as ranges were already allocated.
                if let newAddress = newAddress {
                    try meshNetwork.assign(unicastAddress: newAddress, for: provisioner)
                }
                if disableConfigCapabilities {
                    meshNetwork.disableConfigurationCapabilities(for: provisioner)
                }
            }
            // When we reached that far, changing the name and TTL is just a formality.
            if let newName = newName {
                provisioner.provisionerName = newName
            }
            if let newTtl = newTtl {
                provisioner.node?.defaultTTL = newTtl
            }
            
            if MeshNetworkManager.instance.save() {
                dismiss(animated: true)
                
                // Finally, notify the parent view controller.
                if adding {
                    delegate?.provisionerWasAdded(provisioner)
                } else {
                    delegate?.provisionerWasModified(provisioner)
                }
            } else {
                presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
            }
        } catch {
            switch error as! MeshModelError {
            case .nodeAlreadyExist:
                // A node with the same UUID as the Provisioner has been found.
                // This is very unlikely to happen, as UUIDs are randomly generated.
                // The solution is to go cancel and add another Provisioner, which
                // will have another randomly generated UUID.
                presentAlert(title: "Error", message: "A node for this Provisioner already exists.")
            case .overlappingProvisionerRanges:
                presentAlert(title: "Error", message: "Provisioner's ranges overlap with another Provisioner.")
            case .invalidRange:
                presentAlert(title: "Error", message: "At least one of specified ranges is invalid.")
            case .addressNotInAllocatedRange:
                presentAlert(title: "Error", message: "The Provisioner's address range is outside of its allocated range.")
            case .addressNotAvailable:
                presentAlert(title: "Error", message: "The address is already in use.")
            default:
                presentAlert(title: "Error", message: "An error occurred.")
            }
            return
        }
    }
    
    /// Allocates new ranges, had they changed.
    ///
    /// - parameter provisioner: The Provisioner for which the ranges
    ///                          will be allocated.
    /// - throws: This method may throw if the ranges overlap with
    ///           another Provisioner's range.
    func allocateNewRanges(to provisioner: Provisioner) throws {
        if let newUnicastAddressRange = newUnicastAddressRange {
            provisioner.deallocateUnicastAddressRange(AddressRange.allUnicastAddresses)
            try provisioner.allocateUnicastAddressRanges(newUnicastAddressRange)
        }
        if let newGroupAddressRange = newGroupAddressRange {
            provisioner.deallocateGroupAddressRange(AddressRange.allGroupAddresses)
            try provisioner.allocateGroupAddressRanges(newGroupAddressRange)
        }
        if let newSceneRange = newSceneRange {
            provisioner.deallocateSceneRange(SceneRange.allScenes)
            try provisioner.allocateSceneRanges(newSceneRange)
        }
    }
    
    /// Checks whether the new ranges may be allocated to the given
    /// Provisioner.
    ///
    /// - parameter provisioner: The Provisioner for which the ranges
    ///                          are to be allocated.
    /// - throws: This method may throw if the new ranges are overlapping
    ///           with another Provisioner's ranges.
    func ensureNewRangesAreValid(for provisioner: Provisioner) throws {
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        
        guard newUnicastAddressRange == nil || !newUnicastAddressRange!.isEmpty else {
            throw MeshModelError.invalidRange
        }
        if let newUnicastAddressRange = newUnicastAddressRange {
            guard meshNetwork.areRanges(newUnicastAddressRange, availableForAllocationTo: provisioner) else {
                throw MeshModelError.overlappingProvisionerRanges
            }
        }
        if let newGroupAddressRange = newGroupAddressRange {
            guard meshNetwork.areRanges(newGroupAddressRange, availableForAllocationTo: provisioner) else {
                throw MeshModelError.overlappingProvisionerRanges
            }
        }
        if let newSceneRange = newSceneRange {
            guard meshNetwork.areRanges(newSceneRange, availableForAllocationTo: provisioner) else {
                throw MeshModelError.overlappingProvisionerRanges
            }
        }
    }
    
    /// Checks whether the new address is within Provisioner's range
    /// and is not already taken by any node.
    ///
    /// - parameter provisioner: The Provisioner for which the address
    ///                          will be checked.
    /// - throws: This method may throw if the address is outside of
    ///           Provisioner's range or not available.
    func ensureAddressIsValid(for provisioner: Provisioner) throws {
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        
        if let newAddress = newAddress {
            // Check whether the address is in Provisioner's unicast range.
            let range = newUnicastAddressRange ?? provisioner.allocatedUnicastRange
            guard range.contains(newAddress) else {
                throw MeshModelError.addressNotInAllocatedRange
            }
            
            // Check whether the new address is available.
            guard !meshNetwork.nodes
                .filter({ $0.uuid != provisioner.uuid })
                .contains(where: { $0.unicastAddress == newAddress }) else {
                throw MeshModelError.addressNotAvailable
            }
        }
    }
    
}

extension EditProvisionerViewController: EditRangesDelegate {
    
    func ranges(ofType type: RangeType, haveChangeTo ranges: [RangeObject]) {
        switch type {
        case .unicastAddress:
            unicastAddressRange.clearRanges()
            unicastAddressRange.addRanges(ranges)
            newUnicastAddressRange = ranges as? [AddressRange]
        case .groupAddress:
            groupAddressRange.clearRanges()
            groupAddressRange.addRanges(ranges)
            newGroupAddressRange = ranges as? [AddressRange]
        case .scene:
            sceneRange.clearRanges()
            sceneRange.addRanges(ranges)
            newSceneRange = ranges as? [SceneRange]
        }
    }
    
}

private extension IndexPath {
    static let nameSection    = 0
    static let detailsSection = 1
    static let rangesSection  = 2
    
    /// Returns whether the IndexPath points the Allocated Ranges section.
    var isAllocatedRangesSection: Bool {
        return section == IndexPath.rangesSection
    }
    
    /// Returns whether the IndexPath points the Provisioner name.
    var isProvisionerName: Bool {
        return section == IndexPath.nameSection && row == 0
    }
    
    /// Returns whether the IndexPath point to the Unicast Address.
    var isUnicastAddress: Bool {
        return section == IndexPath.detailsSection && row == 0
    }
    
    /// Returns whether the IndexPath point to the TTL field.
    var isTtl: Bool {
        return section == IndexPath.detailsSection && row == 1
    }
    
    /// Returns whether the IndexPath point to the Device Key.
    var isDeviceKey: Bool {
        return section == IndexPath.detailsSection && row == 2
    }
    
}
