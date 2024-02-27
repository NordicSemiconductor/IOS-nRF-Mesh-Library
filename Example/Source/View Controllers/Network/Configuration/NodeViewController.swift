/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import UIKit
import NordicMesh

class NodeViewController: ProgressViewController {
    
    // MARK: - Public properties
    
    var node: Node!
    /// If this object is set, the app will try to reconfigure the `node` to match the configuration
    /// of this original Node.
    ///
    /// The original Node is set when provisioning replaces a Node that already exists in the network.
    var originalNode: Node?
    
    // MARK: - Outlets
    
    @IBOutlet weak var configureButton: UIBarButtonItem!
    
    // MARK: - Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = node.name ?? "Unknown device"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Element name might have been updated.
        tableView.reloadSections(.editableSections, with: .automatic)
        
        // Check if the local Provisioner has configuration capabilities.
        let localProvisioner = MeshNetworkManager.instance.meshNetwork?.localProvisioner
        guard localProvisioner?.hasConfigurationCapabilities ?? false else {
            // The Provisioner cannot sent or receive messages.
            refreshControl = nil
            return
        }
        
        if refreshControl == nil {
            refreshControl = UIRefreshControl()
            refreshControl!.tintColor = .white
            refreshControl!.addTarget(self, action: #selector(getCompositionData), for: .valueChanged)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        MeshNetworkManager.instance.delegate = self
        
        // Check if the local Provisioner has configuration capabilities.
        let localProvisioner = MeshNetworkManager.instance.meshNetwork?.localProvisioner
        guard localProvisioner?.hasConfigurationCapabilities ?? false else {
            // The Provisioner cannot sent or receive messages.
            return
        }
        
        // If the Composition Data were never obtained, get them now.
        if !node.isCompositionDataReceived {
            // This will request Composition Data when the bearer is open.
            getCompositionData()
            // performSegue(withIdentifier: "reconfigure", sender: nil)
        } else if node.defaultTTL == nil {
            getTtl()
        } else {
            configureButton.isEnabled = node.deviceKey != nil
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showElement" {
            let indexPath = sender as! IndexPath
            let destination = segue.destination as! ElementViewController
            destination.element = node.elements[indexPath.row]
        }
        if segue.identifier == "showNetworkKeys" {
            let destination = segue.destination as! NodeNetworkKeysViewController
            destination.node = node
        }
        if segue.identifier == "showAppKeys" {
            let destination = segue.destination as! NodeAppKeysViewController
            destination.node = node
        }
        if segue.identifier == "showScenes" {
            let destination = segue.destination as! NodeScenesViewController
            destination.node = node
        }
        if segue.identifier == "configure" {
            let navigationController = segue.destination as! ModalNavigationController
            navigationController.modalDelegate = self
            let destination = navigationController.topViewController as! IntroViewController
            destination.node = node
        }
        if segue.identifier == "reconfigure" {
            let navigationController = segue.destination as! ModalNavigationController
            navigationController.modalDelegate = self
            let destination = navigationController.topViewController as! ConfigurationViewController
            destination.configure(node: node, basedOn: sender as! Node)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return IndexPath.numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case IndexPath.nameSection:
            return IndexPath.titles.count
        case IndexPath.nodeSection:
            return IndexPath.nodeTitles.count
        case IndexPath.keysSection:
            return IndexPath.keysTitles.count
        case IndexPath.elementsSection:
            if node.isCompositionDataReceived {
                return node.elements.count
            }
            return 1 // "Composition Data not received" message
        case IndexPath.scenesSection:
            return IndexPath.scenesTitles.count
        case IndexPath.compositionDataSection:
            return IndexPath.detailsTitles.count
        case IndexPath.switchesSection:
            return IndexPath.switchesTitles.count
        case IndexPath.actionsSection:
            return IndexPath.actionsTitles.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case IndexPath.elementsSection:
            return "Elements"
        case IndexPath.compositionDataSection:
            return "Node information"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: indexPath.cellIdentifier, for: indexPath)
        if #available(iOS 13.0, *) {
            cell.textLabel?.textColor = .label
        } else {
            cell.textLabel?.textColor = .darkText
        }
        
        if indexPath.isName {
            cell.textLabel?.text = indexPath.title
            cell.detailTextLabel?.text = node.name ?? "No name"
            cell.accessoryType = .disclosureIndicator
        }
        if indexPath.isNodeSection {
            cell.textLabel?.text = indexPath.title
            if indexPath.isUnicastAddress {
                cell.detailTextLabel?.text = node.primaryUnicastAddress.asString()
                cell.accessoryType = .none
            }
            if indexPath.isTtl {
                cell.detailTextLabel?.text = node.defaultTTL != nil ? "\(node.defaultTTL!)" : "Unknown"
                cell.accessoryType = .disclosureIndicator
            }
            if indexPath.isDeviceKey {
                cell.detailTextLabel?.text = node.deviceKey?.hex ?? "Unknown Device Key"
                cell.accessoryType = .none
            }
        }
        if indexPath.isDetailsSection {
            cell.textLabel?.text = indexPath.title
            cell.accessoryType = .none
            switch indexPath.row {
            case 0:
                if let id = node.companyIdentifier {
                    let name = CompanyIdentifier.name(for: id)
                    cell.detailTextLabel?.text = "\(id.asString()) - " + (name != nil ? name! : "Unknown")
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            case 1:
                if let id = node.productIdentifier {
                    cell.detailTextLabel?.text = "\(id.asString())"
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            case 2:
                if let version = node.versionIdentifier {
                    cell.detailTextLabel?.text = "\(version.asString())"
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            case 3:
                if let rpc = node.minimumNumberOfReplayProtectionList {
                    cell.detailTextLabel?.text = "\(rpc)"
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            case 4:
                if let featuresCell = cell as? NodeFeaturesCell {
                   featuresCell.node = node
                }
            case 5:
                cell.detailTextLabel?.text = "\(node.security)"
                cell.accessoryType = .detailButton
            default:
                break
            }
        }
        if indexPath.isKeysSection {
            cell.textLabel?.text = indexPath.title
            switch indexPath.row {
            case 0: // Network Keys
                cell.detailTextLabel?.text = "\(node.networkKeys.count)"
            default:
                cell.detailTextLabel?.text = "\(node.applicationKeys.count)"
            }
            cell.accessoryType = .disclosureIndicator
        }
        if indexPath.isScenesSection {
            cell.textLabel?.text = indexPath.title
            if node.isCompositionDataReceived,
               let primaryElement = node.primaryElement,
               primaryElement.contains(modelWithSigModelId: .sceneServerModelId) {
                cell.detailTextLabel?.text = "\(node.scenes.count)"
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
            } else {
                cell.detailTextLabel?.text = "Not supported"
                cell.accessoryType = .none
                cell.selectionStyle = .none
            }
        }
        if indexPath.isElementsSection {
            if node.isCompositionDataReceived {
                let element = node.elements[indexPath.row]
                cell.textLabel?.text = element.name ?? "Element \(element.index + 1)"
                cell.detailTextLabel?.text = "\(element.models.count) models"
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
            } else {
                cell.textLabel?.text = "Composition Data not received"
                cell.textLabel?.textColor = .lightGray
                cell.detailTextLabel?.text = nil
                cell.accessoryType = .none
                cell.selectionStyle = .none
            }
        }
        if indexPath.isSwitchesSection {
            let cell = cell as! SwitchCell
            cell.title.text = indexPath.title
            cell.switch.tag = indexPath.row
            cell.switch.addTarget(self, action: #selector(switchDidChangeValue(switch:)), for: .valueChanged)
            switch indexPath.row {
            case 0:
                cell.switch.isOn = node.isConfigComplete
                cell.switch.onTintColor = .nordicLake
            case 1:
                cell.switch.isOn = node.isExcluded
                cell.switch.onTintColor = .nordicRed
            default:
                break
            }
        }
        if indexPath.isActionsSection {
            let cell = cell as! ActionCell
            cell.title.text = indexPath.title
            cell.button.setTitle(indexPath.action, for: .disabled)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if indexPath.isScenesSection {
            return node.primaryElement?.contains(modelWithSigModelId: .sceneServerModelId) ?? false
        }
        return indexPath.isHighlightable
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.isName {
            presentNameDialog()
        }
        if indexPath.isTtl {
            presentTTLDialog()
        }
        if indexPath.isDeviceKey {
            if let hex = node.deviceKey?.hex {
                UIPasteboard.general.string = hex
                showToast("Device Key copied to Clipboard.", delay: .shortDelay)
            } else {
                showToast("No key to copy.", delay: .shortDelay)
            }
        }
        if indexPath.isNetworkKeys {
            performSegue(withIdentifier: "showNetworkKeys", sender: nil)
        }
        if indexPath.isApplicationKeys {
            performSegue(withIdentifier: "showAppKeys", sender: nil)
        }
        if indexPath.isScenesSection {
            performSegue(withIdentifier: "showScenes", sender: nil)
        }
        if indexPath.isElementsSection && node.isCompositionDataReceived {
            performSegue(withIdentifier: "showElement", sender: indexPath)
        }
        if indexPath.isResetNode {
            presentResetConfirmation(from: indexPath)
        }
        if indexPath.isRemoveNode {
            presentRemoveNodeConfirmation(from: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView,
                            accessoryButtonTappedForRowWith indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (IndexPath.compositionDataSection, 5):
            presentAlert(title: "Info", message: "A node is considered secure when it has been provisioned using Out-Of-Band (OOB) Public Key.")
        case (IndexPath.switchesSection, 0):
            presentAlert(title: "Info", message: "Mark a node as configured when you finished setting it up.")
        case (IndexPath.switchesSection, 1):
            presentAlert(title: "Info", message: "If checked, the node will be excluded from key exchange "
                                               + "process. When the key refresh procedure is complete, this "
                                               + "node will no longer be able to receive or send messages to "
                                               + "the mesh network.")
        default:
            break
        }
    }
    
}

private extension NodeViewController {

    /// Presents a dialog to edit the node name.
    func presentNameDialog() {
        presentTextAlert(title: "Name", message: nil, text: node.name,
                         placeHolder: "E.g. Bedroom Light", type: .name, cancelHandler: nil) { name in
                            if name.isEmpty {
                                self.node.name = nil
                            } else {
                                self.node.name = name
                            }
                            
                            if MeshNetworkManager.instance.save() {
                                self.title = self.node.name ?? "Unknown device"
                                self.tableView.reloadRows(at: [.name], with: .automatic)
                            } else {
                                self.presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
                            }
        }
    }
    
    /// Presents a dialog to edit the default TTL.
    func presentTTLDialog() {
        presentTextAlert(title: "Default TTL",
                         message: "TTL = Time To Live\n\nTTL limits the number of times a message can be relayed.\nMax value is 127.",
                         text: node.defaultTTL != nil ? "\(node.defaultTTL!)" : nil,
                         type: .ttlRequired, cancelHandler: nil) { value in
                            let ttl = UInt8(value)!
                            self.setTtl(ttl)
        }
    }
    
    /// Presents a dialog with resetting confirmation.
    func presentResetConfirmation(from indexPath: IndexPath) {
        let alert = UIAlertController(title: "Reset Node",
                                      message: "Resetting the node will change its state back to unprovisioned state and remove it from the local database.",
                                      preferredStyle: .actionSheet)
        let resetAction = UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in self?.resetNode() }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(resetAction)
        alert.addAction(cancelAction)
        let cell = tableView.cellForRow(at: indexPath) as? ActionCell
        alert.popoverPresentationController?.sourceView = cell?.button ?? cell
        alert.popoverPresentationController?.permittedArrowDirections = [.down, .up, .right]
        present(alert, animated: true)
    }
    
    /// Presents a dialog with resetting confirmation.
    func presentRemoveNodeConfirmation(from indexPath: IndexPath) {
        let alert = UIAlertController(title: "Remove Node",
                                      message: "The node will only be removed from the local database. It will still be able to send and receive messages from the network. Remove the node only if the device is no longer available.",
                                      preferredStyle: .actionSheet)
        let resetAction = UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in self?.removeNode() }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(resetAction)
        alert.addAction(cancelAction)
        let cell = tableView.cellForRow(at: indexPath) as? ActionCell
        alert.popoverPresentationController?.sourceView = cell?.button ?? cell
        alert.popoverPresentationController?.permittedArrowDirections = [.down, .up, .right]
        present(alert, animated: true)
    }
    
    /// Method called whenever any switch value changes. The tag contains the row number.
    @objc func switchDidChangeValue(switch: UISwitch) {
        switch `switch`.tag {
        case 0:
            node.isConfigComplete = `switch`.isOn
        case 1:
            node.isExcluded = `switch`.isOn
        default:
            break
        }
        if !MeshNetworkManager.instance.save() {
            presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
        }
    }
    
    @objc func getCompositionData() {
        guard let node = node else {
            return
        }
        start("Requesting Composition Data...") {
            let message = ConfigCompositionDataGet()
            return try MeshNetworkManager.instance.send(message, to: node)
        }
    }
    
    func getTtl() {
        guard let node = node else {
            return
        }
        start("Requesting default TTL...") {
            let message = ConfigDefaultTtlGet()
            return try MeshNetworkManager.instance.send(message, to: node)
        }
    }
    
    func setTtl(_ ttl: UInt8) {
        guard let node = node else {
            return
        }
        start("Setting TTL to \(ttl)...") {
            let message = ConfigDefaultTtlSet(ttl: ttl)
            return try MeshNetworkManager.instance.send(message, to: node)
        }
    }
    
    /// Sends a message to the node that will reset its state to unprovisioned.
    func resetNode() {
        guard let node = node else {
            return
        }
        start("Resetting node...") {
            let message = ConfigNodeReset()
            return try MeshNetworkManager.instance.send(message, to: node)
        }
    }
    
    /// Removes the Node from the local database and pops the Navigation Controller.
    func removeNode() {
        MeshNetworkManager.instance.meshNetwork!.remove(node: node)
        
        if MeshNetworkManager.instance.save() {
            navigationController!.popViewController(animated: true)
        } else {
            presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
        }
    }
    
}

extension NodeViewController: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didReceiveMessage message: MeshMessage,
                            sentFrom source: Address, to destination: MeshAddress) {
        // Has the Node been reset remotely.
        guard !(message is ConfigNodeReset) else {
            (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
            done {
                self.navigationController?.popToRootViewController(animated: true)
            }
            return
        }
        // Is the message targeting the current Node?
        guard node.primaryUnicastAddress == source else {
            return
        }
        
        // Handle the message based on its type.
        switch message {
            
        case is ConfigCompositionDataStatus:
            // When the Composition Data are known, we can try to reconfigure the Node based on
            // how it was configured before.
            if let originalNode = self.originalNode {
                done {
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                    self.configureButton.isEnabled = true
                    
                    self.performSegue(withIdentifier: "reconfigure", sender: originalNode)
                    self.originalNode = nil
                }
                return
            }
            self.getTtl()
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        case is ConfigDefaultTtlStatus:
            done {
                self.tableView.reloadRows(at: [.ttl], with: .automatic)
                self.refreshControl?.endRefreshing()
                self.configureButton.isEnabled = true
            }
            
        case is ConfigNodeResetStatus:
            done {
                self.navigationController?.popViewController(animated: true)
            }
            
        default:
            break
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            failedToSendMessage message: MeshMessage,
                            from localElement: Element, to destination: MeshAddress,
                            error: Error) {
        // Ignore messages sent using model publication.
        guard message is ConfigMessage else {
            return
        }
        done {
            self.presentAlert(title: "Error", message: error.localizedDescription)
            self.refreshControl?.endRefreshing()
        }
    }
    
}

extension NodeViewController: ModalNavigationControllerDelegate {
    
    func modalWillDismiss() {
        tableView.reloadData()
    }
    
}

private extension IndexPath {
    static let nameSection = 0
    static let nodeSection = 1
    static let keysSection = 2
    static let scenesSection = 3
    static let elementsSection = 4
    static let compositionDataSection = 5
    static let switchesSection = 6
    static let actionsSection = 7
    static let numberOfSections = IndexPath.actionsSection + 1
    
    static let titles = [
        "Name"
    ]
    static let nodeTitles = [
        "Unicast Address", "Default TTL", "Device Key"
    ]
    static let keysTitles = [
        "Network Keys", "Application Keys"
    ]
    static let scenesTitles = [
        "Scenes"
    ]
    static let detailsTitles = [
        "Company Identifier", "Product Identifier", "Product Version",
        "Replay Protection Count", nil, // Node Features is using its own cell.
        "Security"
    ]
    static let switchesTitles = [
        "Configured", "Excluded"
    ]
    static let actionsTitles = [
        "Reset Node", "Remove Node"
    ]
    static let actions = [
        "Reset", "Remove"
    ]
    
    var cellIdentifier: String {
        if isNodeFeatures {
            return "features"
        }
        if isDeviceKey {
            return "key"
        }
        if isDetailsSection {
            return "subtitle"
        }
        if isSwitchesSection {
            return "switch"
        }
        if isActionsSection {
            return "action"
        }
        return "normal"
    }
    
    var title: String? {
        if isName {
            return IndexPath.titles[row]
        }
        if isNodeSection {
            return IndexPath.nodeTitles[row]
        }
        if isKeysSection {
            return IndexPath.keysTitles[row]
        }
        if isScenesSection {
            return IndexPath.scenesTitles[row]
        }
        if isDetailsSection {
            return IndexPath.detailsTitles[row]
        }
        if isSwitchesSection {
            return IndexPath.switchesTitles[row]
        }
        if isActionsSection {
            return IndexPath.actionsTitles[row]
        }
        return nil
    }
    
    var action: String? {
        if isActionsSection {
            return IndexPath.actions[row]
        }
        return nil
    }
    
    var isHighlightable: Bool {
        return isName || isTtl || isDeviceKey || isKeysSection
            || isScenesSection || isElementsSection || isActionsSection
    }
    
    var isName: Bool {
        return section == IndexPath.nameSection && row == 0
    }
    
    var isResetNode: Bool {
        return section == IndexPath.actionsSection && row == 0
    }
    
    var isRemoveNode: Bool {
        return section == IndexPath.actionsSection && row == 1
    }
    
    var isUnicastAddress: Bool {
        return isNodeSection && row == 0
    }
    
    var isTtl: Bool {
        return isNodeSection && row == 1
    }
    
    var isDeviceKey: Bool {
        return isNodeSection && row == 2
    }
    
    var isNetworkKeys: Bool {
        return isKeysSection && row == 0
    }
    
    var isApplicationKeys: Bool {
        return isKeysSection && row == 1
    }
    
    var isNodeFeatures: Bool {
        return isDetailsSection && row == 4
    }
    
    var isNodeSection: Bool {
        return section == IndexPath.nodeSection
    }
    
    var isKeysSection: Bool {
        return section == IndexPath.keysSection
    }
    
    var isScenesSection: Bool {
        return section == IndexPath.scenesSection
    }
    
    var isElementsSection: Bool {
        return section == IndexPath.elementsSection
    }
    
    var isDetailsSection: Bool {
        return section == IndexPath.compositionDataSection
    }
    
    var isSwitchesSection: Bool {
        return section == IndexPath.switchesSection
    }
    
    var isActionsSection: Bool {
        return section == IndexPath.actionsSection
    }
    
    static let name  = IndexPath(row: 0, section: IndexPath.nameSection)
    static let ttl   = IndexPath(row: 1, section: IndexPath.nodeSection)
    
}

private extension IndexSet {
    
    static let editableSections = IndexSet(integersIn: IndexPath.keysSection...IndexPath.compositionDataSection)
    
}
