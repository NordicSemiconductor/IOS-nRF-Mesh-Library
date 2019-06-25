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
    
    // MARK: - Outlets -
    @IBOutlet weak var organizeButton: UIBarButtonItem!
    
    @IBOutlet weak var networkNameLabel: UILabel!
    @IBOutlet weak var provisionersLabel: UILabel!
    @IBOutlet weak var networkKeysLabel: UILabel!
    @IBOutlet weak var appKeysLabel: UILabel!
    
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
        
        let manager = MeshNetworkManager.instance
        if manager.save() {
            // Reload network data.
            let meshNetwork = manager.meshNetwork!
            networkNameLabel.text  = meshNetwork.meshName
            provisionersLabel.text = "\(meshNetwork.provisioners.count)"
            networkKeysLabel.text  = "\(meshNetwork.networkKeys.count)"
            appKeysLabel.text      = "\(meshNetwork.applicationKeys.count)"
        } else {
            self.presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
        }
    }
    
    /// Exports Mesh Network configuration and opens UIActivityViewController
    /// which allows user to share it.
    func exportNetwork() {
        let manager = MeshNetworkManager.instance
        
        DispatchQueue.global(qos: .userInitiated).async {
            let data = manager.export()
            
            do {
                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("mesh.json")
                try data.write(to: fileURL)
                
                DispatchQueue.main.async {
                    let controller = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                    controller.popoverPresentationController?.barButtonItem = self.organizeButton
                    self.present(controller, animated: true)
                }
            } catch {
                self.presentAlert(title: "Error", message: "Exporting Mesh Network configuration failed.")
                print("Export failed: \(error)")
            }
        }
    }
    
    /// Opens the Cocument Picker to select the Mesh Network configuration to import.
    func importNetwork() {
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
    
    /// Returns whether the IndexPath point to the mesh network name row.
    var isNetworkName: Bool {
        return section == 0 && row == 0
    }
    
    /// Returns whether the IndexPath point to the network resetting option.
    var isResetNetwork: Bool {
        return section == 1 && row == 0
    }
    
    /// Returns whether the IndexPath point to the Source Code link.
    var isLinkToGitHub: Bool {
        return section == 2 && row == 2
    }
    
    /// Returns whether the IndexPath point to the Issues on GitHub.
    var isLinkToIssues: Bool {
        return section == 2 && row == 3
    }
    
    static let name = IndexPath(row: 0, section: 1)
}

private extension IndexSet {
    
    static let networkSection = IndexSet(integer: 0)
    
}
