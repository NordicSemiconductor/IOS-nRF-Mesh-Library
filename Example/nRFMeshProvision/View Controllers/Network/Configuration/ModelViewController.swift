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
        
        refreshControl = UIRefreshControl()
        refreshControl!.tintColor = UIColor.white
        refreshControl!.addTarget(self, action: #selector(reloadBindings(_:)), for: .valueChanged)
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
        case .some("subscribe"):
            let destination = segue.destination as! UINavigationController
            let viewController = destination.topViewController as! SubscribeViewController
            viewController.model = model
            viewController.delegate = self
        default:
            break
        }
    }
    
    // MARK: - Table View Controller
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if model.isBluetoothSIGAssigned && model.isConfigurationServer {
            // TODO: Add Relay and Transmit controls.
            return 1
        }
        if model.isBluetoothSIGAssigned && model.isConfigurationClient {
            return 1
        }
        return 4 // TODO: Add Custom sections
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case IndexPath.detailsSection:
            return IndexPath.detailsTitles.count
        case IndexPath.bindingsSection:
            return model.boundApplicationKeys.count + 1 // Add Action.
        case IndexPath.publishSection:
            return 1 // Set Publication Action or the Publication.
        case IndexPath.subscribeSection:
            return model.subscriptions.count + 1 // Add Action.
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
            guard let publish = model.publish else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
                cell.textLabel?.text = "Set Publication"
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "destination", for: indexPath)
            let address = publish.publicationAddress
            if address.address.isUnicast {
                let meshNetwork = MeshNetworkManager.instance.meshNetwork!
                let node = meshNetwork.node(withAddress: address.address)
                if let element = node?.element(withAddress: address.address) {
                    if let name = element.name {
                        cell.textLabel?.text = name
                        cell.detailTextLabel?.text = node?.name ?? "Unknown Device"
                    } else {
                        let index = node!.elements.firstIndex(of: element)!
                        let name = "Element \(index + 1)"
                        cell.textLabel?.text = name
                        cell.detailTextLabel?.text = node?.name ?? "Unknown Device"
                    }
                } else {
                    cell.textLabel?.text = "Unknown Element"
                    cell.detailTextLabel?.text = "Unknown Node"
                }
                cell.tintColor = .nordicLake
                cell.imageView?.image = #imageLiteral(resourceName: "ic_flag_24pt")
            } else if address.address.isGroup || address.address.isVirtual {
                switch address.address {
                case .allProxies:
                    cell.textLabel?.text = "All Proxies"
                    cell.detailTextLabel?.text = nil
                case .allFriends:
                    cell.textLabel?.text = "All Friends"
                    cell.detailTextLabel?.text = nil
                case .allRelays:
                    cell.textLabel?.text = "All Relays"
                    cell.detailTextLabel?.text = nil
                case .allNodes:
                    cell.textLabel?.text = "All Nodes"
                    cell.detailTextLabel?.text = nil
                default:
                    let meshNetwork = MeshNetworkManager.instance.meshNetwork!
                    if let group = meshNetwork.group(withAddress: address) {
                        cell.textLabel?.text = group.name
                        cell.detailTextLabel?.text = nil
                    } else {
                        cell.textLabel?.text = "Unknown group"
                        cell.detailTextLabel?.text = address.asString()
                    }
                }
                cell.imageView?.image = #imageLiteral(resourceName: "outline_group_work_black_24pt")
                cell.tintColor = .nordicLake
            } else {
                cell.textLabel?.text = "Invalid address"
                cell.detailTextLabel?.text = nil
                cell.tintColor = .nordicRed
                cell.imageView?.image = #imageLiteral(resourceName: "ic_flag_24pt")
            }
            return cell
        }
        if indexPath.isSubscribeSection {
            guard indexPath.row < model.subscriptions.count else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
                cell.textLabel?.text = "Subscribe"
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "group", for: indexPath)
            let group = model.subscriptions[indexPath.row]
            cell.textLabel?.text = group.name
            cell.detailTextLabel?.text = nil
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
            return true
        }
        if indexPath.isSubscribeSection {
            return indexPath.row == model.subscriptions.count
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
            guard !model.boundApplicationKeys.isEmpty else {
                presentAlert(title: "Application Key required", message: "Bind at least one Application Key before setting the publication.")
                return
            }
            performSegue(withIdentifier: "publish", sender: indexPath)
        }
        if indexPath.isSubscribeSection {
            // Only the "Subscribe" row is selectable.
            performSegue(withIdentifier: "subscribe", sender: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.isBindingsSection {
            return indexPath.row < model.boundApplicationKeys.count
        }
        if indexPath.isPublishSection {
            return indexPath.row == 0 && model.publish != nil
        }
        if indexPath.isSubscribeSection {
            return indexPath.row < model.subscriptions.count
        }
        return false
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if indexPath.isBindingsSection {
            return [UITableViewRowAction(style: .destructive, title: "Unbind", handler: { _, indexPath in
                guard indexPath.row < self.model.boundApplicationKeys.count else {
                        return
                }
                let applicationKey = self.model.boundApplicationKeys[indexPath.row]
                
                // Let's check if the key that's being unbound is set for publication.
                let boundKeyUsedInPublication = self.model.publish?.index == applicationKey.index
                // Check also, if any other Node is set to publish to this Model
                // (using parent Element's Unicast Address) using this key.
                let network = MeshNetworkManager.instance.meshNetwork!
                let thisElement = self.model.parentElement!
                let thisNode = thisElement.parentNode!
                let otherNodes = network.nodes.filter { $0 != thisNode }
                let elementsWithCompatibleModels = otherNodes.flatMap {
                    $0.elements.filter({ $0.contains(modelCompatibleWith: self.model, boundTo: applicationKey)})
                }
                let compatibleModels = elementsWithCompatibleModels.flatMap {
                    $0.models.filter({ $0.isCompatible(to: self.model) && $0.boundApplicationKeys.contains(applicationKey) })
                }
                let boundKeyUsedByOtherNodes = compatibleModels.contains {
                        $0.publish?.publicationAddress.address == thisElement.unicastAddress &&
                            $0.publish?.index == applicationKey.index
                }
                
                if boundKeyUsedInPublication || boundKeyUsedByOtherNodes {
                    var message = "The key you want to unbind is set"
                    if boundKeyUsedInPublication {
                        message += " in the publication settings in this model"
                        if boundKeyUsedByOtherNodes {
                            message += " and"
                        }
                    }
                    if boundKeyUsedByOtherNodes {
                        message += " in at least one model on another node that publish directly to this element."
                    }
                    if boundKeyUsedInPublication {
                        if boundKeyUsedByOtherNodes {
                            message += " The local publication will be cancelled automatically, but other nodes will not be affected. This model will no longer be able to handle those publications."
                        } else {
                            message += "\nThe publication will be cancelled automatically."
                        }
                    }
                    self.confirm(title: "Key in use", message: message, handler: { _ in
                        self.unbindApplicationKey(applicationKey)
                    })
                } else {
                    self.unbindApplicationKey(applicationKey)
                }
            })]
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.isPublishSection {
            removePublication()
        }
        if indexPath.isSubscribeSection {
            let group = model.subscriptions[indexPath.row]
            unsubscribe(from: group)
        }
    }

}

private extension ModelViewController {
    
    @objc func reloadBindings(_ sender: Any) {
        whenConnected { alert in
            alert?.message = "Reading Bound Application Keys..."
            guard let message: ConfigMessage =
                ConfigSIGModelAppGet(of: self.model) ??
                ConfigVendorModelAppGet(of: self.model) else {
                    self.done()
                    return
            }
            MeshNetworkManager.instance.send(message, to: self.model)
        }
    }
    
    func reloadPublication() {
        whenConnected { alert in
            alert?.message = "Reading Publication settings..."
            MeshNetworkManager.instance.send(ConfigModelPublicationGet(for: self.model), to: self.model)
        }
    }
    
    func reloadSubscriptions() {
        whenConnected { alert in
            alert?.message = "Reading Subscriptions..."
            guard let message: ConfigMessage =
                ConfigSIGModelSubscriptionGet(of: self.model) ??
                ConfigVendorModelSubscriptionGet(of: self.model) else {
                    self.done()
                    return
            }
            MeshNetworkManager.instance.send(message, to: self.model)
        }
    }
    
    /// Sends a message to the mesh network to unbind the given Application Key
    /// from the Model.
    ///
    /// - parameter applicationKey: The Application Key to unbind.
    func unbindApplicationKey(_ applicationKey: ApplicationKey) {
        whenConnected { alert in
            alert?.message = "Unbinding Application Key"
            MeshNetworkManager.instance.send(ConfigModelAppUnbind(applicationKey: applicationKey, to: self.model), to: self.model)
        }
    }
    
    /// Removes the publicaton from the model.
    func removePublication() {
        whenConnected { alert in
            alert?.message = "Removing Publication..."
            MeshNetworkManager.instance.send(ConfigModelPublicationSet(disablePublicationFor: self.model), to: self.model)
        }
    }
    
    /// Unsubscribes the Model from publications sent to the given Group.
    ///
    /// - parameter group: The Group to be removed from subscriptions.
    func unsubscribe(from group: Group) {
        whenConnected { alert in
            alert?.message = "Unsubscribing..."
            guard let message: ConfigMessage =
                ConfigModelSubscriptionDelete(group: group, from: self.model) ??
                ConfigModelSubscriptionVirtualAddressDelete(group: group, from: self.model) else {
                    return
            }
            MeshNetworkManager.instance.send(message, to: self.model)
        }
    }
    
}

extension ModelViewController: MeshNetworkDelegate {
    
    func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, from source: Address) {
        switch message {
            
        case let status as ConfigModelAppStatus:
            done()
            
            if status.isSuccess {
                tableView.reloadSections(.bindingsAndPublication, with: .automatic)
                setEditing(false, animated: true)
            } else {
                presentAlert(title: "Error", message: status.message)
            }
            
        case let status as ConfigModelPublicationStatus:
            done()
        
            if status.isSuccess {
                tableView.reloadSections(.publication, with: .automatic)
                setEditing(false, animated: true)
            } else {
                presentAlert(title: "Error", message: status.message)
            }
            refreshControl?.endRefreshing()
            
        case let status as ConfigModelSubscriptionStatus:
            done()
            
            if status.isSuccess {
                tableView.reloadSections(.subscriptions, with: .automatic)
                setEditing(false, animated: true)
            } else {
                presentAlert(title: "Error", message: status.message)
            }
            
        case let list as ConfigModelAppList:
            if list.isSuccess {
                tableView.reloadSections(.bindingsAndPublication, with: .automatic)
                reloadSubscriptions()
            } else {
                done() {
                    self.presentAlert(title: "Error", message: list.message)
                    self.refreshControl?.endRefreshing()
                }
            }
            
        case let list as ConfigModelSubscriptionList:
            if list.isSuccess {
                tableView.reloadSections(.subscriptions, with: .automatic)
                reloadPublication()
            } else {
                done() {
                    self.presentAlert(title: "Error", message: list.message)
                    self.refreshControl?.endRefreshing()
                }
            }
            
        case is ConfigNodeReset:
            // The node has been reset remotely.
            (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
            done() {
                self.navigationController?.popToRootViewController(animated: true)
            }
            
        default:
            break
        }
    }
    
}

extension ModelViewController: BindAppKeyDelegate, PublicationDelegate, SubscriptionDelegate {
    
    func keyBound() {
        tableView.reloadSections(.bindings, with: .automatic)
    }
    
    func publicationChanged() {
        tableView.reloadSections(.publication, with: .automatic)
    }
    
    func subscriptionAdded() {
        tableView.reloadSections(.subscriptions, with: .automatic)
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
    
    var isSubscribeSection: Bool {
        return section == IndexPath.subscribeSection
    }
    
}

private extension IndexSet {
    
    static let bindings = IndexSet(integer: IndexPath.bindingsSection)
    static let publication = IndexSet(integer: IndexPath.publishSection)
    static let subscriptions = IndexSet(integer: IndexPath.subscribeSection)
    static let bindingsAndPublication = IndexSet([IndexPath.bindingsSection, IndexPath.publishSection])
    
}
