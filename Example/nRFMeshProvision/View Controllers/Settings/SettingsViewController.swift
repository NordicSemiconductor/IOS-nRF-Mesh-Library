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

class SettingsViewController: UITableViewController {
    
    // MARK: - Outlets -
    @IBOutlet weak var organizeButton: UIBarButtonItem!
    
    @IBOutlet weak var networkNameLabel: UILabel!
    @IBOutlet weak var provisionersLabel: UILabel!
    @IBOutlet weak var networkKeysLabel: UILabel!
    @IBOutlet weak var appKeysLabel: UILabel!
    @IBOutlet weak var testModeSwitch: UISwitch!
    @IBAction func testModeDidChange(_ sender: UISwitch) {
        MeshNetworkManager.instance.ivUpdateTestMode = sender.isOn
    }
    
    @IBOutlet weak var resetNetworkButton: UIButton!
    
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var appBuildNumberLabel: UILabel!
    
    // MARK: - IBActions
    
    @IBAction func organizeTapped(_ sender: UIBarButtonItem) {
        displayImportExportOptions()
    }
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load versions.
        appVersionLabel.text = AppInfo.version
        appBuildNumberLabel.text = AppInfo.buildNumber
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let manager = MeshNetworkManager.instance
        
        let meshNetwork = manager.meshNetwork!
        networkNameLabel.text  = meshNetwork.meshName
        provisionersLabel.text = "\(meshNetwork.provisioners.count)"
        networkKeysLabel.text  = "\(meshNetwork.networkKeys.count)"
        appKeysLabel.text      = "\(meshNetwork.applicationKeys.count)"
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.isNetworkName {
            presentNameDialog()
        }
        if indexPath.isResetNetwork {
            presentResetConfirmation()
        }
        if indexPath.isLinkToGitHub {
            if let url = URL(string: "https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library") {
                UIApplication.shared.open(url)
            }
        }
        if indexPath.isLinkToIssues {
            if let url = URL(string: "https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library/issues") {
                UIApplication.shared.open(url)
            }
        }
    }
    
}

private extension SettingsViewController {
    
    /// Presents a dialog to edit the network name.
    func presentNameDialog() {
        let network = MeshNetworkManager.instance.meshNetwork!
        
        presentTextAlert(title: "Network Name", message: nil, text: network.meshName,
                         placeHolder: "E.g. My House", type: .nameRequired) { name in
                            network.meshName = name
                            
                            if MeshNetworkManager.instance.save() {
                                self.networkNameLabel.text = name
                            } else {
                                self.presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
                            }
        }
    }
    
    /// Presents a dialog with resetting confirmation.
    func presentResetConfirmation() {
        let alert = UIAlertController(title: "Reset Network",
                                      message: "Resetting the network will erase all network data.\nMake sure you exported it first.",
                                      preferredStyle: .actionSheet)
        let resetAction = UIAlertAction(title: "Reset", style: .destructive) { _ in self.resetNetwork() }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(resetAction)
        alert.addAction(cancelAction)
        alert.popoverPresentationController?.sourceView = resetNetworkButton
        present(alert, animated: true)
    }
    
    /// Displays the Import / Export action sheet.
    func displayImportExportOptions() {
        let alert = UIAlertController(title: "Organize",
                                      message: "Importing network will override your existing settings.\nMake sure you exported it first.",
                                      preferredStyle: .actionSheet)
        let exportAction = UIAlertAction(title: "Export", style: .default) { _ in self.exportNetwork() }
        let importAction = UIAlertAction(title: "Import", style: .destructive) { _ in self.importNetwork() }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(exportAction)
        alert.addAction(importAction)
        alert.addAction(cancelAction)
        alert.popoverPresentationController?.barButtonItem = organizeButton
        present(alert, animated: true)
    }
    
    /// Resets all network settings to default values.
    func resetNetwork() {
        (UIApplication.shared.delegate as! AppDelegate).createNewMeshNetwork()
        MeshNetworkManager.instance.ivUpdateTestMode = false
        testModeSwitch.setOn(false, animated: true)
        
        if MeshNetworkManager.instance.save() {
            reload()
        } else {
            presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
        }
    }
    
    /// Exports Mesh Network configuration and opens UIActivityViewController
    /// which allows user to share it.
    func exportNetwork() {
        let manager = MeshNetworkManager.instance
        
        DispatchQueue.global(qos: .userInitiated).async {
            let data = manager.export()
            
            do {
                let name = manager.meshNetwork?.meshName ?? "mesh"
                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).json")
                try data.write(to: fileURL)
                
                DispatchQueue.main.async {
                    let controller = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                    controller.popoverPresentationController?.barButtonItem = self.organizeButton
                    self.present(controller, animated: true)
                }
            } catch {
                print("Export failed: \(error)")
                DispatchQueue.main.async {
                    self.presentAlert(title: "Error", message: "Exporting Mesh Network configuration failed.")
                }
            }
        }
    }
    
    /// Opens the Document Picker to select the Mesh Network configuration to import.
    func importNetwork() {
        let picker = UIDocumentPickerViewController(documentTypes: ["public.data", "public.content"], in: .import)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    /// Reloads network data.
    func reload() {
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        networkNameLabel.text  = meshNetwork.meshName
        provisionersLabel.text = "\(meshNetwork.provisioners.count)"
        networkKeysLabel.text  = "\(meshNetwork.networkKeys.count)"
        appKeysLabel.text      = "\(meshNetwork.applicationKeys.count)"
        MeshNetworkManager.instance.ivUpdateTestMode = false
        testModeSwitch.setOn(false, animated: true)
        
        // All tabs should be reset to the root view controller.
        parent?.parent?.children.forEach {
            if let rootViewController = $0 as? UINavigationController {
                rootViewController.popToRootViewController(animated: false)
            }
        }
    }
}

// MARK: - UIDocumentPickerDelegate -

extension SettingsViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let manager = MeshNetworkManager.instance
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: url)
                let meshNetwork = try manager.import(from: data)
                // Try restoring the Provisioner used last time on this device.
                var provisionerSet = true
                if !meshNetwork.restoreLocalProvisioner() {
                    // If it's a new network, try creating a new Provisioner.
                    // This will succeed if available ranges are found.
                    if let nextAddressRange = meshNetwork.nextAvailableUnicastAddressRange(ofSize: 0x199A),
                       let nextGroupRange = meshNetwork.nextAvailableGroupAddressRange(ofSize: 0x0C9A),
                       let nextSceneRange = meshNetwork.nextAvailableSceneRange(ofSize: 0x3334) {
                        let newProvisioner = Provisioner(name: UIDevice.current.name,
                                                         allocatedUnicastRange: [nextAddressRange],
                                                         allocatedGroupRange: [nextGroupRange],
                                                         allocatedSceneRange: [nextSceneRange])
                        // Set it a a new local Provisioner.
                        try? meshNetwork.setLocalProvisioner(newProvisioner)
                        // And assign a Unicast Address to it.
                        if let address = meshNetwork.nextAvailableUnicastAddress(for: newProvisioner) {
                            try? meshNetwork.assign(unicastAddress: address, for: newProvisioner)
                        }
                    } else {
                        provisionerSet = false
                    }
                }
                
                if manager.save() {
                    DispatchQueue.main.async {
                        (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
                        self.reload()
                        if provisionerSet {
                            self.presentAlert(title: "Success", message: "Mesh Network configuration imported.")
                        } else {
                            self.presentAlert(title: "Warning", message: "Mesh Network configuration imported successfully, but the provisioner could not be set. All ranges are already assigned. Go to Settings -> Provisioners and create a new provisioner manually. Until then this device may not be able to send mesh messages.")
                        }
                    }
                } else {
                    self.presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
                }
            } catch {
                print("Import failed: \(error)")
                DispatchQueue.main.async {
                    self.presentAlert(title: "Error", message: "Importing Mesh Network configuration failed.\nCheck if the file is valid.")
                }
            }
        }
    }
    
}

private extension IndexPath {
    static let nameSection    = 0
    static let networkSection = 1
    static let actionsSection = 2
    static let aboutSection   = 3
    
    /// Returns whether the IndexPath point to the mesh network name row.
    var isNetworkName: Bool {
        return section == IndexPath.nameSection && row == 0
    }
    
    /// Returns whether the IndexPath point to the network resetting option.
    var isResetNetwork: Bool {
        return section == IndexPath.actionsSection && row == 0
    }
    
    /// Returns whether the IndexPath point to the Source Code link.
    var isLinkToGitHub: Bool {
        return section == IndexPath.aboutSection && row == 2
    }
    
    /// Returns whether the IndexPath point to the Issues on GitHub.
    var isLinkToIssues: Bool {
        return section == IndexPath.aboutSection && row == 3
    }
    
    static let name = IndexPath(row: 0, section: IndexPath.nameSection)
}
