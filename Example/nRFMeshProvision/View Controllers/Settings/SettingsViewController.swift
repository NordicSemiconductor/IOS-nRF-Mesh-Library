//
//  SettingsViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 18/03/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class SettingsViewController: UITableViewController {
    
    // MARK: - IBOutlets -
    @IBOutlet weak var globalTTL: UITableViewCell!
    
    @IBOutlet weak var networkName: UITableViewCell!
    @IBOutlet weak var provisioners: UITableViewCell!
    @IBOutlet weak var networkKeys: UITableViewCell!
    @IBOutlet weak var appKeys: UITableViewCell!
    
    @IBOutlet weak var appVersion: UITableViewCell!
    @IBOutlet weak var appBuildNumber: UITableViewCell!
    
    // MARK: - IBActions -
    
    @IBAction func organizeTapped(_ sender: UIBarButtonItem) {
        displayImportExportOptions()
    }
    
    // MARK: - Implementation -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load versions.
        appVersion.detailTextLabel?.text = AppInfo.version
        appBuildNumber.detailTextLabel?.text = AppInfo.buildNumber
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let manager = MeshNetworkManager.instance
        globalTTL.detailTextLabel?.text = "\(manager.globalTTL)"
        
        let meshNetwork = manager.meshNetwork!
        networkName.detailTextLabel?.text  = meshNetwork.meshName
        provisioners.detailTextLabel?.text = "\(meshNetwork.provisioners.count)"
        networkKeys.detailTextLabel?.text  = "\(meshNetwork.networkKeys.count)"
        appKeys.detailTextLabel?.text      = "\(meshNetwork.applicationKeys.count)"
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.isDefaultTTL {
            presentTTLDialog()
        }
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

extension SettingsViewController {
    
    private func presentTTLDialog() {
        let manager = MeshNetworkManager.instance
        
        presentTextAlert(title: "Default TTL",
                         message: "TTL = Time To Leave\n\nTTL limits the number of times a message can be relayed.\nMax value is 127.",
                         text: "\(manager.globalTTL)", placeHolder: "Default is 5",
                         type: .ttlRequired) { value in
                            let ttl = UInt8(value)!
                            manager.globalTTL = ttl
                            
                            if MeshNetworkManager.instance.save() {
                                self.globalTTL.detailTextLabel?.text = "\(ttl)"
                            } else {
                                self.presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
                            }
        }
    }
    
    /// Presents a dialog to edit the network name.
    private func presentNameDialog() {
        let network = MeshNetworkManager.instance.meshNetwork!
        
        presentTextAlert(title: "Network Name", message: nil, text: network.meshName,
                         placeHolder: "E.g. My House", type: .nameRequired) { name in
                            network.meshName = name
                            
                            if MeshNetworkManager.instance.save() {
                                self.networkName.detailTextLabel?.text = name
                            } else {
                                self.presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
                            }
        }
    }
    
    /// Presents a dialog with resetting confirmation.
    private func presentResetConfirmation() {
        let alert = UIAlertController(title: "Reset Network",
                                      message: "Resetting the network will erase all network data.\nMake sure you exported it first.",
                                      preferredStyle: .actionSheet)
        let resetAction = UIAlertAction(title: "Reset", style: .destructive) { _ in self.resetNetwork() }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(resetAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    /// Displays the Import / Export action sheet.
    private func displayImportExportOptions() {
        let alert = UIAlertController(title: "Organize",
                                      message: "Importing network will override your existing settings.\nMake sure you exported it first.",
                                      preferredStyle: .actionSheet)
        let exportAction = UIAlertAction(title: "Export", style: .default) { _ in self.exportNetwork() }
        let importAction = UIAlertAction(title: "Import", style: .destructive) { _ in self.importNetwork() }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(exportAction)
        alert.addAction(importAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    /// Resets all network settings to default values.
    private func resetNetwork() {
        let manager = MeshNetworkManager.instance
        // TODO: Implement creator
        _ = manager.createNewMeshNetwork(named: "nRF Mesh Network", by: UIDevice.current.name)
        
        if manager.save() {
            // Reload network data.
            let meshNetwork = manager.meshNetwork!
            networkName.detailTextLabel?.text  = meshNetwork.meshName
            provisioners.detailTextLabel?.text = "\(meshNetwork.provisioners.count)"
            networkKeys.detailTextLabel?.text  = "\(meshNetwork.networkKeys.count)"
            appKeys.detailTextLabel?.text      = "\(meshNetwork.applicationKeys.count)"
        } else {
            self.presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
        }
    }
    
    /// Exports Mesh Network configuration and opens UIActivityViewController
    /// which allows user to share it.
    private func exportNetwork() {
        let manager = MeshNetworkManager.instance
        
        DispatchQueue.global(qos: .userInitiated).async {
            let data = manager.export()
            
            do {
                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("mesh.json")
                try data.write(to: fileURL)
                
                DispatchQueue.main.async {
                    let controller = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                    self.present(controller, animated: true)
                }
            } catch {
                self.presentAlert(title: "Error", message: "Exporting Mesh Network configuration failed.")
                print("Export failed: \(error)")
            }
        }
    }
    
    /// Opens the Cocument Picker to select the Mesh Network configuration to import.
    private func importNetwork() {
        let picker = UIDocumentPickerViewController(documentTypes: ["public.data", "public.content"], in: .import)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
}

// MARK: - UIDocumentPickerDelegate -

extension SettingsViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let manager = MeshNetworkManager.instance
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: url)
                try manager.import(from: data)
                
                self.presentAlert(title: "Success", message: "Mesh Network configuration imported.")
            } catch {
                self.presentAlert(title: "Error", message: "Importing Mesh Network configuration failed.\nCheck if the file is valid.")
                print("Import failed: \(error)")
            }
        }
    }
    
}


private extension IndexPath {
    
    /// Returns whether the IndexPath point to the default TTL.
    var isDefaultTTL: Bool {
        return section == 0 && row == 0
    }
    
    /// Returns whether the IndexPath point to the mesh network name row.
    var isNetworkName: Bool {
        return section == 1 && row == 0
    }
    
    /// Returns whether the IndexPath point to the network resetting option.
    var isResetNetwork: Bool {
        return section == 2 && row == 0
    }
    
    /// Returns whether the IndexPath point to the Source Code link.
    var isLinkToGitHub: Bool {
        return section == 3 && row == 2
    }
    
    /// Returns whether the IndexPath point to the Issues on GitHub.
    var isLinkToIssues: Bool {
        return section == 3 && row == 3
    }
    
    static let name = IndexPath(row: 0, section: 1)
}

private extension IndexSet {
    
    static let networkSection = IndexSet(integer: 1)
    
}
