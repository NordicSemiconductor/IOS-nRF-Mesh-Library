//
//  ModelViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/07/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class ModelViewController: ConnectableViewController {

    // MARK: - Properties
    
    var model: Model!
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = model.name ?? "Model"
        navigationItem.rightBarButtonItem = editButtonItem
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        MeshNetworkManager.instance.delegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case .some("bind"):
            let destination = segue.destination as! UINavigationController
            let viewController = destination.topViewController as! ModelBindAppKeyViewController
            viewController.model = model
            viewController.delegate = self
        case .some("publish"):
            let destination = segue.destination as! UINavigationController
            let viewController = destination.topViewController as! SetPublicationViewController
            viewController.model = model
            viewController.delegate = self
        default:
            break
        }
    }
    
    // MARK: - Table View Controller
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if model.isBluetoothSIGAssigned && model.isConfigurationServer {
            // TODO: Add Relay and Transmit controlls.
            return 1
        }
        if model.isBluetoothSIGAssigned && model.isConfigurationClient {
            return 1
        }
        return 3 // TODO: Add Subscribe and custom sections
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case IndexPath.detailsSection:
            return IndexPath.detailsTitles.count
        case IndexPath.bindingsSection:
            return model.boundApplicationKeys.count + 1 // Add Action.
        case IndexPath.publishSection:
            return model.publish != nil ? 2 : 1 // Set Publication Action.
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case IndexPath.bindingsSection:
            return "Bound Application Keys"
        case IndexPath.publishSection:
            return "Publication"
        case IndexPath.subscribeSection:
            return "Subscriptions"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.isDetailsSection {
            let cell = tableView.dequeueReusableCell(withIdentifier: "normal", for: indexPath)
            cell.textLabel?.text = indexPath.title
            if indexPath.isModelId {
                cell.detailTextLabel?.text = model.modelIdentifier.asString()
            }
            if indexPath.isCompany {
                if model.isBluetoothSIGAssigned {
                    cell.detailTextLabel?.text = "Bluetooth SIG"
                } else {
                    if let companyId = model.companyIdentifier {
                        if let companyName = CompanyIdentifier.name(for: companyId) {
                            cell.detailTextLabel?.text = companyName
                        } else {
                            cell.detailTextLabel?.text = "Unknown Company ID (\(companyId.asString()))"
                        }
                    } else {
                        cell.detailTextLabel?.text = "Unknown Company ID"
                    }
                }
            }
            return cell
        }
        if indexPath.isBindingsSection {
            guard indexPath.row < model.boundApplicationKeys.count else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
                cell.textLabel?.text = "Bind Application Key"
                return cell
            }
            let applicationKey = model.boundApplicationKeys[indexPath.row]
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "key", for: indexPath)
            cell.textLabel?.text = applicationKey.name
            cell.detailTextLabel?.text = "Bound to \(applicationKey.boundNetworkKey.name)"
            return cell
        }
        if indexPath.isPublishSection {
            guard let publish = model.publish, indexPath.row == 0 else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
                cell.textLabel?.text = "Set Publication"
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "normal", for: indexPath)
            let address = publish.publicationAddress
            if address.isVirtual {
                cell.textLabel?.text = "Virtual label"
            } else if address.address.isUnicast {
                cell.textLabel?.text = "Unicast address"
            } else if address.address.isGroup {
                cell.textLabel?.text = "Group address"
            } else {
                cell.textLabel?.text = "Invalid address"
            }
            cell.detailTextLabel?.text = "\(address)"
            return cell
        }
        // Not possible.
        return tableView.dequeueReusableCell(withIdentifier: "normal", for: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if indexPath.isBindingsSection {
            return indexPath.row == model.boundApplicationKeys.count
        }
        if indexPath.isPublishSection {
            return indexPath.row > 0 || model.publish == nil
        }
        return false
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.isBindingsSection {
            // Only the "Bind" row is selectable.
            performSegue(withIdentifier: "bind", sender: indexPath)
        }
        if indexPath.isPublishSection {
            // Only Add Publication is selectable.
            guard !model.boundApplicationKeys.isEmpty else {
                presentAlert(title: "Application Key required", message: "Bind at least one Application Key before setting the publication.")
                return
            }
            performSegue(withIdentifier: "publish", sender: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.isBindingsSection {
            return indexPath.row < model.boundApplicationKeys.count
        }
        if indexPath.isPublishSection {
            return indexPath.row == 0 && model.publish != nil
        }
        return false
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if indexPath.isBindingsSection {
            return [UITableViewRowAction(style: .destructive, title: "Unbind",
                                         handler: { _, indexPath in self.unbindApplicationKey(at: indexPath) })]
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.isPublishSection {
            
        }
    }

}

private extension ModelViewController {
    
    /// Sends a message to the mesh network to unbind the Application Key
    /// from given indexPath from the Model.
    ///
    /// - parameter indexPath: An IndexPath pointing the Application Key
    //                         to unbind.
    func unbindApplicationKey(at indexPath: IndexPath) {
        whenConnected { action in
            guard let node = self.model.parentElement.parentNode,
                indexPath.row < self.model.boundApplicationKeys.count else {
                self.done()
                return
            }
            let applicationKey = self.model.boundApplicationKeys[indexPath.row]
            action?.message = "Unbinding Application Key"
            MeshNetworkManager.instance.send(ConfigModelAppUnbind(applicationKey: applicationKey, to: self.model), to: node)
        }
    }
    
}

extension ModelViewController: MeshNetworkDelegate {
    
    func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, from source: Address) {
        switch message {
        case let status as ConfigModelAppStatus:
            done()
            
            if status.isSuccess {
                tableView.reloadSections(.bindings, with: .automatic)
                setEditing(false, animated: true)
            } else {
                presentAlert(title: "Error", message: "\(status.status)")
            }
        default:
            break
        }
    }
    
}

extension ModelViewController: BindAppKeyDelegate, PublicationDelegate {
    
    func keyBound() {
        tableView.reloadSections(.bindings, with: .automatic)
    }
    
    func publicationChanged() {
        tableView.reloadSections(.publication, with: .automatic)
    }
    
}

private extension Model {
    
    var isConfigurationServer: Bool {
        return isBluetoothSIGAssigned && modelIdentifier == 0x0000
    }
    
    var isConfigurationClient: Bool {
        return isBluetoothSIGAssigned && modelIdentifier == 0x0001
    }
    
}

private extension IndexPath {
    static let detailsSection   = 0
    static let bindingsSection  = 1
    static let publishSection   = 2
    static let subscribeSection = 3
    
    static let detailsTitles = [
        "Model ID", "Company"
    ]
    
    var title: String? {
        if isDetailsSection {
            return IndexPath.detailsTitles[row]
        }
        return nil
    }
    
    var isModelId: Bool {
        return isDetailsSection && row == 0
    }
    
    var isCompany: Bool {
        return isDetailsSection && row == 1
    }
    
    var isDetailsSection: Bool {
        return section == IndexPath.detailsSection
    }
    
    var isBindingsSection: Bool {
        return section == IndexPath.bindingsSection
    }
    
    var isPublishSection: Bool {
        return section == IndexPath.publishSection
    }
}

private extension IndexSet {
    
    static let bindings = IndexSet(integer: IndexPath.bindingsSection)
    static let publication = IndexSet(integer: IndexPath.publishSection)
    
}
