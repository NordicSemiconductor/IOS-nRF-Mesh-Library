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
import nRFMeshProvision

class ExportViewController: UITableViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    // MARK: - Actions
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        if full {
            exportNetwork(using: .full)
        } else {
            exportNetwork(using: .partial(
                            // Export selected Network Keys:
                            networkKeys: .some(selectedNetworkKeys),
                            // Export all Application Keys bound to selected Network Keys:
                            applicationKeys: .all,
                            // Export selected Provisioners:
                            provisioners: .some(selectedProvisioners),
                            // The library allows to share some nodes with the Device Key,
                            // and some without, but for simplicity use the same setting
                            // for all:
                            nodes: exportDeviceKeys ? .allWithDeviceKey : .allWithoutDeviceKey,
                            // Export related Groups and Scenes.
                            // Related means those used by exported Nodes, and configured
                            // to be used with any of the exported Application Keys.
                            groups: .related, scenes: .related))
        }
    }
    
    // MARK: - Private properties
    
    private var full: Bool = true
    private var exportDeviceKeys: Bool = true
    private var selectedProvisioners: [Provisioner] = []
    private var selectedNetworkKeys: [NetworkKey] = []
    
    // MARK: - View Controller
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "newProvisioner" {
            let target = segue.destination as! UINavigationController
            let viewController = target.topViewController as! EditProvisionerViewController
            viewController.delegate = self
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return full ? 1 : IndexPath.numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let network = MeshNetworkManager.instance.meshNetwork else {
            return 0
        }
        switch section {
        case IndexPath.configSection:
            return 1 // Full or Partial
        case IndexPath.provisionersSection:
            return network.provisioners.count + 1 // Action: New
        case IndexPath.networkKeysSection:
            return network.networkKeys.count
        case IndexPath.optionsSection:
            return 1 // Export Device Keys row
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case IndexPath.configSection:
            return "Configuration"
        case IndexPath.provisionersSection:
            return "Provisioners"
        case IndexPath.networkKeysSection:
            return "Network Keys"
        case IndexPath.optionsSection:
            return "Options"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case IndexPath.configSection:
            return full ? "Full configuration will contain all mesh network data stored on this device.\n\n"
                        + "When sharing with a Guest, consider creating a new network key and set of guest "
                        + "application keys, send them to nodes that you want to share with the guest, and "
                        + "bind to required models. Then export only this network key with excluded device "
                        + "keys.\n\n"
                        + "The underlying library allows also to specify which nodes, groups or scenes are "
                        + "to be shared. This app will only share those, that use the specified network key." : nil
        case IndexPath.provisionersSection:
            return "At least one Provisioner must be selected."
        case IndexPath.networkKeysSection:
            return "At least one Network Key must be selected. Only Nodes that store selected keys and "
                 + "Application Keys bound to them will be exported."
        case IndexPath.optionsSection:
            return "Device Keys allow nodes to be reconfigured or reset (removed from network)."
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let network = MeshNetworkManager.instance.meshNetwork!
        
        switch indexPath.section {
        case IndexPath.configSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: "switch", for: indexPath) as! SwitchCell
            cell.title.text = IndexPath.configurationTitles[indexPath.row]
            cell.title.isEnabled = true
            cell.switch.isOn = full
            cell.switch.isEnabled = true
            cell.switch.removeTarget(nil, action: nil, for: .allEvents)
            cell.switch.addTarget(self, action: #selector(modeDidChange(_:)), for: .valueChanged)
            return cell
        case IndexPath.provisionersSection where indexPath.row < network.provisioners.count:
            let cell = tableView.dequeueReusableCell(withIdentifier: "normal", for: indexPath)
            let provisioner = network.provisioners[indexPath.row]
            cell.textLabel?.text = provisioner.name
            cell.textLabel?.isEnabled = !full
            cell.imageView?.image = #imageLiteral(resourceName: "ic_security_24pt")
            cell.accessoryType = !full && selectedProvisioners.contains(provisioner) ? .checkmark : .none
            cell.selectionStyle = !full ? .default : .none
            return cell
        case IndexPath.provisionersSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: "button", for: indexPath)
            cell.textLabel?.text = "New"
            cell.textLabel?.isEnabled = !full
            cell.selectionStyle = !full ? .default : .none
            return cell
        case IndexPath.networkKeysSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: "normal", for: indexPath)
            let networkKey = network.networkKeys[indexPath.row]
            cell.textLabel?.text = networkKey.name
            cell.textLabel?.isEnabled = !full
            cell.imageView?.image = #imageLiteral(resourceName: "ic_vpn_key_24pt")
            cell.accessoryType = !full && selectedNetworkKeys.contains(networkKey) ? .checkmark : .none
            cell.selectionStyle = !full ? .default : .none
            return cell
        case IndexPath.optionsSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: "switch", for: indexPath) as! SwitchCell
            cell.title.text = IndexPath.detailsTitles[indexPath.row]
            cell.title.isEnabled = !full
            cell.switch.isOn = indexPath.row == 0 && exportDeviceKeys
            cell.switch.isEnabled = !full
            cell.switch.removeTarget(nil, action: nil, for: .allEvents)
            cell.switch.addTarget(self, action: #selector(exportDeviceKeysDidChange(_:)), for: .valueChanged)
            return cell
        default:
            fatalError("Too many sections Export View Controller")
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let network = MeshNetworkManager.instance.meshNetwork else {
            return
        }
        
        switch indexPath.section {
        case IndexPath.provisionersSection where indexPath.row < network.provisioners.count:
            let selectedProvisioner = network.provisioners[indexPath.row]
            if let index = selectedProvisioners.firstIndex(of: selectedProvisioner) {
                selectedProvisioners.remove(at: index)
            } else {
                selectedProvisioners.append(selectedProvisioner)
            }
            tableView.reloadSections(.provisioners, with: .automatic)
        case IndexPath.provisionersSection:
            performSegue(withIdentifier: "newProvisioner", sender: nil)
        case IndexPath.networkKeysSection:
            let selectedNetworkKey = network.networkKeys[indexPath.row]
            if let index = selectedNetworkKeys.firstIndex(of: selectedNetworkKey) {
                selectedNetworkKeys.remove(at: index)
            } else {
                selectedNetworkKeys.append(selectedNetworkKey)
            }
            tableView.reloadSections(.networkKeys, with: .automatic)
        default:
            break
        }
        
        doneButton.isEnabled = full || (!selectedProvisioners.isEmpty && !selectedNetworkKeys.isEmpty)
    }
}

extension ExportViewController: EditProvisionerDelegate {
    
    func provisionerWasAdded(_ provisioner: Provisioner) {
        selectedProvisioners.append(provisioner)
        tableView.reloadSections(.provisioners, with: .automatic)
    }
    
    func provisionerWasModified(_ provisioner: Provisioner) {
        // Impossible.
    }
    
}

private extension ExportViewController {
    
    @objc func modeDidChange(_ control: UISwitch) {
        full = control.isOn
        tableView.beginUpdates()
        tableView.reloadSections(.config, with: .automatic)
        if full {
            tableView.deleteSections(.all, with: .fade)
        } else {
            tableView.insertSections(.all, with: .fade)
        }
        tableView.endUpdates()
        doneButton.isEnabled = full || (!selectedProvisioners.isEmpty && !selectedNetworkKeys.isEmpty)
    }
    
    @objc func exportDeviceKeysDidChange(_ control: UISwitch) {
        exportDeviceKeys = control.isOn
    }
    
    /// Exports the mesh network data using the given configuration.
    ///
    /// - parameter exportConfiguration: The configuration containing information which
    ///                                  parameters are to be exported.
    func exportNetwork(using exportConfiguration: ExportConfiguration) {
        let manager = MeshNetworkManager.instance
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let data = manager.export(exportConfiguration)
            
            do {
                let name = manager.meshNetwork?.meshName ?? "mesh"
                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).json")
                try data.write(to: fileURL)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let controller = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                    controller.popoverPresentationController?.barButtonItem = self.doneButton
                    controller.completionWithItemsHandler = { [weak self] type, success, items, error in
                        guard let self = self else { return }
                        if success {
                            self.dismiss(animated: true)
                        } else {
                            if let error = error {
                                print("Export failed: \(error)")
                                self.presentAlert(title: "Error",
                                                  message: "Exporting Mesh Network configuration failed "
                                                         + "with error \(error.localizedDescription).")
                            }
                        }
                    }
                    self.present(controller, animated: true)
                }
            } catch {
                print("Export failed: \(error)")
                DispatchQueue.main.async { [weak self] in
                    self?.presentAlert(title: "Error",
                                       message: "Exporting Mesh Network configuration failed "
                                              + "with error \(error.localizedDescription).")
                }
            }
        }
    }
    
}

private extension IndexPath {
    
    static let configSection = 0
    static let provisionersSection = 1
    static let networkKeysSection = 2
    static let optionsSection = 3
    static let numberOfSections = optionsSection + 1
    
    static let configurationTitles = [
        "Export Everything"
    ]
    
    static let detailsTitles = [
        "Export Device Keys"
    ]
    
}

private extension IndexSet {
    
    static let all = IndexSet(integersIn: 1..<IndexPath.numberOfSections)
    static let config = IndexSet([IndexPath.configSection])
    static let provisioners = IndexSet([IndexPath.provisionersSection])
    static let networkKeys = IndexSet([IndexPath.networkKeysSection])
    static let options = IndexSet([IndexPath.optionsSection])
    
}
