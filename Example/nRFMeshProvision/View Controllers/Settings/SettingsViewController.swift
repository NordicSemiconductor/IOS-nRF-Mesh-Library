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
    }
    
    // MARK: - Export / Import -
    
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
