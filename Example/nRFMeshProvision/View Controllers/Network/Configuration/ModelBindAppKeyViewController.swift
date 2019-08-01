//
//  ModelBindAppKeyViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/07/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

protocol BindAppKeyDelegate {
    /// This method is called when a new Application Key has been bound to the Model.
    func keyBound()
}

class ModelBindAppKeyViewController: ConnectableViewController {
    
    // MARK: - Outlets and Actions
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        bind()
    }
    
    // MARK: - Properties
    
    var model: Model!
    var delegate: BindAppKeyDelegate?
    
    private var keys: [ApplicationKey]!
    private var selectedIndexPath: IndexPath?
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEmptyView(title: "No keys available", message: "Add a new key to the node first.", messageImage: #imageLiteral(resourceName: "baseline-key"))
        
        MeshNetworkManager.instance.delegate = self
        
        keys = model.parentElement?.parentNode?.applicationKeysAvailableFor(model)
        if keys.isEmpty {
            tableView.showEmptyView()
        }
        // Initially, no key is checked.
        doneButton.isEnabled = false
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return keys.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let key = keys[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = key.name
        cell.detailTextLabel?.text = "Bound to \(key.boundNetworkKey.name)"
        cell.accessoryType = indexPath == selectedIndexPath ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var rows: [IndexPath] = []
        if let selectedIndexPath = selectedIndexPath {
            rows.append(selectedIndexPath)
        }
        rows.append(indexPath)
        selectedIndexPath = indexPath
        tableView.reloadRows(at: rows, with: .automatic)
        
        doneButton.isEnabled = true
    }

}

private extension ModelBindAppKeyViewController {
    
    func bind() {
        guard let selectedIndexPath = selectedIndexPath else {
            return
        }
        let selectedAppKey = keys[selectedIndexPath.row]
        whenConnected() { alert in
            alert?.message = "Binding Application Key..."
            MeshNetworkManager.instance.send(ConfigModelAppBind(applicationKey: selectedAppKey, to: self.model), to: self.model)
        }
    }
    
}

extension ModelBindAppKeyViewController: MeshNetworkDelegate {
    
    func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, from source: Address) {
        // Has the Node been reset remotely.
        guard !(message is ConfigNodeReset) else {
            (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
            done() {
                let rootViewControllers = self.presentingViewController?.children
                self.dismiss(animated: true) {
                    rootViewControllers?.forEach {
                        if let navigationController = $0 as? UINavigationController {
                            navigationController.popToRootViewController(animated: true)
                        }
                    }
                }
            }
            return
        }
        // Is the message targetting the current Node?
        guard model.parentElement.parentNode!.unicastAddress == source else {
            return
        }
        
        // Handle the message based on its type.
        switch message {
            
        case let status as ConfigModelAppStatus:
            done() {
                if status.status == .success {
                    self.dismiss(animated: true)
                    self.delegate?.keyBound()
                } else {
                    self.presentAlert(title: "Error", message: "\(status.status)")
                }
            }
            
        default:
            // Ignore
            break
        }
    }
    
}
