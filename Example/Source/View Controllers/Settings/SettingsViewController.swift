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
    
    // MARK: - Outlets
    @IBOutlet weak var organizeButton: UIBarButtonItem!
    
    @IBOutlet weak var networkNameLabel: UILabel!
    @IBOutlet weak var provisionersLabel: UILabel!
    @IBOutlet weak var networkKeysLabel: UILabel!
    @IBOutlet weak var appKeysLabel: UILabel!
    @IBOutlet weak var scenesLabel: UILabel!
    @IBOutlet weak var testModeSwitch: UISwitch!
    @IBOutlet weak var lastModifiedLabel: UILabel!
    @IBAction func testModeDidChange(_ sender: UISwitch) {
        MeshNetworkManager.instance.networkParameters.ivUpdateTestMode = sender.isOn
    }
    
    @IBOutlet weak var resetNetworkButton: UIButton!
    
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var appBuildNumberLabel: UILabel!
    
    // MARK: - Actions
    
    @IBAction func organizeTapped(_ sender: UIBarButtonItem) {
        displayImportExportOptions()
    }
    
    // MARK: - Private members
    
    private let dateFormatter = DateFormatter()
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        // Load versions.
        appVersionLabel.text = AppInfo.version
        appBuildNumberLabel.text = AppInfo.buildNumber
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // If the network has not been created, open a New Network Wizard.
        guard MeshNetworkManager.instance.isNetworkCreated else {
            openNewNetworkWizard()
            return
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "wizard" {
            let nc = segue.destination as! UINavigationController
            let wizard = nc.topViewController as! WizardViewController
            wizard.delegate = self
        }
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
    
    override func tableView(_ tableView: UITableView,
                            accessoryButtonTappedForRowWith indexPath: IndexPath) {
        if indexPath.isIvUpdateTestMode {
            presentAlert(title: "Info",
                         message: "IV Update test mode allows to transition to the subsequent "
                                + "IV Index without having to wait at least 96 hours. The "
                                + "transition will be done upon receiving a valid Secure Network beacon.")
        }
    }
    
}

extension SettingsViewController: WizardDelegate {
    
    /// Opens the Document Picker to select the Mesh Network configuration to import.
    func importNetwork() {
        let picker = UIDocumentPickerViewController(documentTypes: ["public.data", "public.content"], in: .import)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    func createNetwork(withFixedKeys fixed: Bool,
                       networkKeys: Int, applicationKeys: Int,
                       groups: Int, virtualGroups: Int, scenes: Int) {
        let network = (UIApplication.shared.delegate as! AppDelegate).createNewMeshNetwork()
        
        var index: UInt8 = 1
        // In debug mode, with fixed keys, the primary network key added by default has to be
        // removed and replaced with a one with fixed value.
        if fixed {
            try? network.remove(networkKeyWithKeyIndex: 0, force: true)
            let key = Data(repeating: 0, count: 15) + index
            index += 1
            _ = try? network.add(networkKey: key, name: "Primary Network Key")
        }
        // Add random or fixed key Network and Application Keys.
        for i in 1..<networkKeys {
            guard index < UInt8.max else { break }
            let key = fixed ? Data(repeating: 0, count: 15) + index : Data.random128BitKey()
            index += 1
            _ = try? network.add(networkKey: key, name: "Network Key \(i + 1)")
        }
        for i in 0..<applicationKeys {
            guard index < UInt8.max else { break }
            let key = fixed ? Data(repeating: 0, count: 15) + index : Data.random128BitKey()
            index += 1
            _ = try? network.add(applicationKey: key, name: "Application Key \(i + 1)")
        }
        // Add groups and scenes.
        for i in 0..<groups {
            if let address = network.nextAvailableGroupAddress() {
                _ = try? network.add(group: Group(name: "Group \(i + 1)", address: address))
            }
        }
        for i in 0..<virtualGroups {
            _ = try? network.add(group: Group(name: "Virtual Group \(i + 1)", address: MeshAddress(UUID())))
        }
        for i in 0..<scenes {
            if let sceneNumber = network.nextAvailableScene() {
                _ = try? network.add(scene: sceneNumber, name: "Scene \(i + 1)")
            }
        }
        
        if MeshNetworkManager.instance.save() {
            reload()
            resetViews()
        } else {
            presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
        }
    }
    
}

private extension SettingsViewController {
    
    /// Presents a dialog to edit the network name.
    func presentNameDialog() {
        let network = MeshNetworkManager.instance.meshNetwork!
        
        presentTextAlert(title: "Network Name", message: nil, text: network.meshName,
                         placeHolder: "E.g. My House", type: .nameRequired, cancelHandler: nil) { name in
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
                                      message: "Resetting the network will erase all network data.\n"
                                             + "Make sure you exported it first.",
                                      preferredStyle: .actionSheet)
        let resetAction = UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            _ = MeshNetworkManager.instance.clear()
            self?.openNewNetworkWizard()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(resetAction)
        alert.addAction(cancelAction)
        alert.popoverPresentationController?.sourceView = resetNetworkButton
        present(alert, animated: true)
    }
    
    /// Displays the Import / Export action sheet.
    func displayImportExportOptions() {
        let alert = UIAlertController(title: "Organize",
                                      message: "Importing network will override your existing settings.\n"
                                             + "Make sure you exported it first.",
                                      preferredStyle: .actionSheet)
        let exportAction = UIAlertAction(title: "Export", style: .default) { [weak self] _ in self?.exportNetwork() }
        let importAction = UIAlertAction(title: "Import", style: .destructive) { [weak self] _ in self?.importNetwork() }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(exportAction)
        alert.addAction(importAction)
        alert.addAction(cancelAction)
        alert.popoverPresentationController?.barButtonItem = organizeButton
        present(alert, animated: true)
    }
    
    /// Opens the Export popup with export options.
    func exportNetwork() {
        performSegue(withIdentifier: "export", sender: nil)
    }
    
    func openNewNetworkWizard() {
        performSegue(withIdentifier: "wizard", sender: nil)
    }
    
    /// Reloads network data.
    func reload() {
        guard let meshNetwork = MeshNetworkManager.instance.meshNetwork else {
            return
        }
        networkNameLabel.text  = meshNetwork.meshName
        provisionersLabel.text = "\(meshNetwork.provisioners.count)"
        networkKeysLabel.text  = "\(meshNetwork.networkKeys.count)"
        appKeysLabel.text      = "\(meshNetwork.applicationKeys.count)"
        scenesLabel.text       = "\(meshNetwork.scenes.count)"
        lastModifiedLabel.text = dateFormatter.string(from: meshNetwork.timestamp)
        tableView.reloadData()
    }
     
    func resetViews() {
        // IV Update Test Mode is not persistent and has to be set each time
        // the app is open or a network is imported.
        MeshNetworkManager.instance.networkParameters.ivUpdateTestMode = false
        testModeSwitch.setOn(false, animated: true)
        
        // All tabs should be reset to the root view controller.
        parent?.parent?.children
            .compactMap { $0 as? UINavigationController }
            .forEach { $0.popToRootViewController(animated: false) }
    }
    
    /// Saves mesh network configuration and reloads network data on success.
    func saveAndReload() {
        if MeshNetworkManager.instance.save() {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
                self.reload()
                self.resetViews()
                self.presentAlert(title: "Success", message: "Mesh Network configuration imported.")
            }
        } else {
            self.presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
        }
    }
}

// MARK: - UIDocumentPickerDelegate -

extension SettingsViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let manager = MeshNetworkManager.instance
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let data = try Data(contentsOf: url)
                let meshNetwork = try manager.import(from: data)
                // Try restoring the Provisioner used last time on this device.
                if !meshNetwork.restoreLocalProvisioner() {
                    // If it's a new network and has only one Provisioner, just save it.
                    // Otherwise, give the user option to select one.
                    if meshNetwork.provisioners.count > 1 {
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            let alert = UIAlertController(title: "Select Provisioner",
                                                          message: "Select Provisioner instance to be used on this device:",
                                                          preferredStyle: .actionSheet)
                            alert.popoverPresentationController?.barButtonItem = self.organizeButton
                            for provisioner in meshNetwork.provisioners {
                                alert.addAction(UIAlertAction(title: provisioner.name, style: .default) { [weak self] action in
                                    // This will effectively set the Provisioner to be used
                                    // be the library. Provisioner from index 0 is the local one.
                                    meshNetwork.moveProvisioner(provisioner, toIndex: 0)
                                    self?.saveAndReload()
                                })
                            }
                            self.present(alert, animated: true)
                        }
                        return
                    }
                }
                self.saveAndReload()
            } catch let DecodingError.dataCorrupted(context) {
                let path = context.codingPath.path
                print("Import failed: \(context.debugDescription) (\(path))")
                DispatchQueue.main.async { [weak self] in
                    self?.presentAlert(title: "Error",
                                       message: "Importing Mesh Network configuration failed.\n"
                                              + "\(context.debugDescription)\nPath: \(path).")
                }
            } catch let DecodingError.keyNotFound(key, context) {
                let path = context.codingPath.path
                print("Import failed: Key \(key) not found in \(path)")
                DispatchQueue.main.async { [weak self] in
                    self?.presentAlert(title: "Error",
                                       message: "Importing Mesh Network configuration failed.\n"
                                              + "No value associated with key: \(key.stringValue) in: \(path).")
                }
            } catch let DecodingError.valueNotFound(value, context) {
                let path = context.codingPath.path
                print("Import failed: Value of type \(value) required in \(path)")
                DispatchQueue.main.async { [weak self] in
                    self?.presentAlert(title: "Error",
                                       message: "Importing Mesh Network configuration failed.\n"
                                              + "No value associated with key: \(path).")
                }
            } catch let DecodingError.typeMismatch(type, context) {
                let path = context.codingPath.path
                print("Import failed: Type mismatch in \(path) (\(type) was required)")
                DispatchQueue.main.async { [weak self] in
                    self?.presentAlert(title: "Error",
                                       message: "Importing Mesh Network configuration failed.\n"
                                              + "Type mismatch in: \(path). Expected: \(type).")
                }
            } catch {
                print("Import failed: \(error)")
                DispatchQueue.main.async { [weak self] in
                    self?.presentAlert(title: "Error",
                                       message: "Importing Mesh Network configuration failed.\n"
                                              + "Check if the file is valid.")
                }
            }
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // If importing new network was cancelled and there is no previous network, open
        // the Wizard.
        let manager = MeshNetworkManager.instance
        guard let _ = manager.meshNetwork else {
            openNewNetworkWizard()
            return
        }
    }
    
}

private extension IndexPath {
    static let nameSection    = 0
    static let networkSection = 1
    static let dateSection    = 2
    static let actionsSection = 3
    static let aboutSection   = 4
    
    /// Returns whether the IndexPath points to the mesh network name row.
    var isNetworkName: Bool {
        return section == IndexPath.nameSection && row == 0
    }
    
    /// Returns whether the IndexPath points to the IV Update Test Mode switch row.
    var isIvUpdateTestMode: Bool {
        return section == IndexPath.networkSection && row == 4
    }
    
    /// Returns whether the IndexPath points to the network resetting option.
    var isResetNetwork: Bool {
        return section == IndexPath.actionsSection && row == 0
    }
    
    /// Returns whether the IndexPath points to the Source Code link.
    var isLinkToGitHub: Bool {
        return section == IndexPath.aboutSection && row == 2
    }
    
    /// Returns whether the IndexPath points to the Issues on GitHub.
    var isLinkToIssues: Bool {
        return section == IndexPath.aboutSection && row == 3
    }
    
    static let name = IndexPath(row: 0, section: IndexPath.nameSection)
}

private extension Array where Element == CodingKey {
    
    var path: String {
        return reduce("root") { (result, node) -> String in
            if let range = node.stringValue.range(of: #"(\d+)$"#,
                                                  options: .regularExpression) {
                return "\(result)[\(node.stringValue[range])]"
            }
            return "\(result)→\(node.stringValue)"
        }
    }
    
}
