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

class ModelViewController: ProgressViewController {

    // MARK: - Properties
    
    var model: Model!
    
    private weak var modelViewCell: ModelViewCell?
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = model.name ?? "Model"
        if !model.isConfigurationClient {
            navigationItem.rightBarButtonItem = editButtonItem
        }
        
        tableView.register(UINib(nibName: "ConfigurationServer", bundle: nil), forCellReuseIdentifier: "0000")
        tableView.register(UINib(nibName: "GenericOnOff", bundle: nil), forCellReuseIdentifier: "1000")
        tableView.register(UINib(nibName: "GenericLevel", bundle: nil), forCellReuseIdentifier: "1002")
        tableView.register(UINib(nibName: "VendorModel", bundle: nil), forCellReuseIdentifier: "vendor")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Check if the local Provisioner has configuration capabilities.
        let localProvisioner = MeshNetworkManager.instance.meshNetwork?.localProvisioner
        guard localProvisioner?.hasConfigurationCapabilities ?? false else {
            // The Provisioner cannot sent or receive messages.
            refreshControl = nil
            editButtonItem.isEnabled = false
            return
        }
        
        if !model.isConfigurationClient {
            refreshControl = UIRefreshControl()
            refreshControl!.tintColor = UIColor.white
            refreshControl!.addTarget(self, action: #selector(reload(_:)), for: .valueChanged)
        }
        editButtonItem.isEnabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        MeshNetworkManager.instance.delegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navigationController = segue.destination as? UINavigationController
        navigationController?.presentationController?.delegate = self
        
        switch segue.identifier {
        case .some("bind"):
            let viewController = navigationController?.topViewController as! ModelBindAppKeyViewController
            viewController.model = model
            viewController.delegate = self
        case .some("heartbeatPublication"):
            let viewController = navigationController?.topViewController as! SetHeartbeatPublicationViewController
            viewController.node = model.parentElement!.parentNode!
            viewController.delegate = self
        case .some("heartbeatSubscription"):
            let viewController = navigationController?.topViewController as! SetHeartbeatSubscriptionViewController
            viewController.node = model.parentElement!.parentNode!
            viewController.delegate = self
        case .some("publish"):
            let viewController = navigationController?.topViewController as! SetPublicationViewController
            viewController.model = model
            viewController.delegate = self
        case .some("subscribe"):
            let viewController = navigationController?.topViewController as! SubscribeViewController
            viewController.model = model
            viewController.delegate = self
        default:
            break
        }
    }
    
    // MARK: - Table View Controller
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if model.isConfigurationServer {
            // Details, Configuration Server Cell, Heartbeat Publication, Heartbeat Subsctiption
            return 4
        }
        if model.isConfigurationClient {
            // Details only
            return 1
        }
        if model.hasCustomUI {
            // Details, Bind App Key, Publish, Subscribe, Custom UI
            return 5
        }
        // Details, Bind App Key, Publish, Subscribe
        return 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case IndexPath.detailsSection:
            return IndexPath.detailsTitles.count
        case IndexPath.configurationServerSection where model.isConfigurationServer:
            return 1
        case IndexPath.bindingsSection:
            return model.boundApplicationKeys.count + 1 // Add Action.
        case IndexPath.publishSection:
            return 1 // Set Publication Action or the Publication.
        case IndexPath.subscribeSection where model.isConfigurationServer:
            return 1 // Subscription or Set Action (only one Heartbeat Subscription is allowed).
        case IndexPath.subscribeSection:
            return model.subscriptions.count + 1 // Add Action.
        default:
            // If we went that far, there has to be a supported UI for the Model.
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case IndexPath.configurationServerSection where model.isConfigurationServer:
            return "Relay Count & Interval"
        case IndexPath.bindingsSection:
            return "Bound Application Keys"
        case IndexPath.publishSection where model.isConfigurationServer:
            return "Heartbeat Publication"
        case IndexPath.subscribeSection where model.isConfigurationServer:
            return "Heartbeat Subscription"
        case IndexPath.publishSection:
            return "Publication"
        case IndexPath.subscribeSection:
            return "Subscriptions"
        default:
            return "Controls"
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let localProvisioner = MeshNetworkManager.instance.meshNetwork?.localProvisioner
        
        // All models have the Details section.
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
        // The second section may either be App Key Binding (for all Models, except Configuration Server)
        // or Configuration Server Cell.
        if indexPath.isBindingsSection && !model.isConfigurationServer {
            guard indexPath.row < model.boundApplicationKeys.count else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
                cell.textLabel?.text = "Bind Application Key"
                cell.textLabel?.isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
                return cell
            }
            let applicationKey = model.boundApplicationKeys[indexPath.row]
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "key", for: indexPath)
            cell.textLabel?.text = applicationKey.name
            cell.detailTextLabel?.text = "Bound to \(applicationKey.boundNetworkKey.name)"
            return cell
        }
        // Third section is the Pubilcation or Heartbeat Publication section (in case of Configuration Server)
        if indexPath.isPublishSection {
            if model.isConfigurationServer {
                guard let publication = model.parentElement?.parentNode?.heartbeatPublication else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
                    cell.textLabel?.text = "Set Publication"
                    cell.textLabel?.isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
                    return cell
                }
                let cell = tableView.dequeueReusableCell(withIdentifier: "heartbeatPublication", for: indexPath) as! HeartbeatPublicationCell
                cell.heartbeatPublication = publication
                return cell
            } else {
                guard let publish = model.publish else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
                    cell.textLabel?.text = "Set Publication"
                    cell.textLabel?.isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
                    return cell
                }
                let cell = tableView.dequeueReusableCell(withIdentifier: "destination", for: indexPath) as! PublicationCell
                cell.publish = publish
                return cell
            }
        }
        // Fourth section is the Subscribe or Heartbeat Subscription section (in case of Configuration Server)
        if indexPath.isSubscribeSection {
            if model.isConfigurationServer {
                guard let subscription = model.parentElement?.parentNode?.heartbeatSubscription else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
                    cell.textLabel?.text = "Subscribe"
                    cell.textLabel?.isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
                    return cell
                }
                let cell = tableView.dequeueReusableCell(withIdentifier: "heartbeatSubscription", for: indexPath) as! HeartbeatSubscriptionCell
                cell.subscription = subscription
                return cell
            } else {
                guard indexPath.row < model.subscriptions.count else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
                    cell.textLabel?.text = "Subscribe"
                    cell.textLabel?.isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
                    return cell
                }
                let cell = tableView.dequeueReusableCell(withIdentifier: "group", for: indexPath)
                let group = model.subscriptions[indexPath.row]
                cell.textLabel?.text = group.name
                cell.detailTextLabel?.text = nil
                return cell
            }
        }
        // A custom cell for the Model.
        let identifier = model.isBluetoothSIGAssigned ? model.modelIdentifier.hex : "vendor"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! ModelViewCell
        cell.delegate = self
        cell.model    = model
        modelViewCell = cell
        return cell
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let localProvisioner = MeshNetworkManager.instance.meshNetwork?.localProvisioner
        guard localProvisioner?.hasConfigurationCapabilities ?? false else {
            return false
        }
        
        if indexPath.isBindingsSection && !model.isConfigurationServer {
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
            if model.isConfigurationServer {
                performSegue(withIdentifier: "heartbeatPublication", sender: indexPath)
            } else {
                guard !model.boundApplicationKeys.isEmpty else {
                    presentAlert(title: "Application Key required",
                                 message: "Bind at least one Application Key before setting the publication.")
                    return
                }
                performSegue(withIdentifier: "publish", sender: indexPath)
            }
        }
        if indexPath.isSubscribeSection {
            if model.isConfigurationServer {
                performSegue(withIdentifier: "heartbeatSubscription", sender: indexPath)
            } else {
                // Only the "Subscribe" row is selectable.
                performSegue(withIdentifier: "subscribe", sender: indexPath)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.isBindingsSection {
            return indexPath.row < model.boundApplicationKeys.count
        }
        if indexPath.isPublishSection {
            if model.isConfigurationServer {
                return model.parentElement?.parentNode?.heartbeatPublication != nil
            } else {
                return indexPath.row == 0 && model.publish != nil
            }
        }
        if indexPath.isSubscribeSection {
            if model.isConfigurationServer {
                return model.parentElement?.parentNode?.heartbeatSubscription != nil
            } else {
                return indexPath.row < model.subscriptions.count
            }
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
                    $0.elements.filter({ $0.contains(modelBoundTo: applicationKey)})
                }
                let compatibleModels = elementsWithCompatibleModels.flatMap {
                    $0.models.filter({ $0.isBoundTo(applicationKey) })
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
    
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if indexPath.isPublishSection {
            if model.isConfigurationServer {
                removeHeartbeatPublication()
            } else {
                removePublication()
            }
        }
        if indexPath.isSubscribeSection {
            if model.isConfigurationServer {
                removeHeartbeatSubscription()
            } else {
                let group = model.subscriptions[indexPath.row]
                unsubscribe(from: group)
            }
        }
    }

}

extension ModelViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        MeshNetworkManager.instance.delegate = self
    }
    
}

extension ModelViewController: ModelViewCellDelegate {
    
    func send(_ message: MeshMessage, description: String) {
        start(description) {
            return try MeshNetworkManager.instance.send(message, to: self.model)
        }
    }
    
    func send(_ message: ConfigMessage, description: String) {
        start(description) {
            return try MeshNetworkManager.instance.send(message, to: self.model)
        }
    }
    
    var isRefreshing: Bool {
        return refreshControl?.isRefreshing ?? false
    }
    
}

private extension ModelViewController {
    
    @objc func reload(_ sender: Any) {
        switch model! {
        case let model where model.isConfigurationServer:
            // First, load heartbeat publication, which will trigger reading
            // heartbeat subescription, which will load custom UI.
            reloadHeartbeatPublication()
        default:
            // Model App Bindings -> Subscriptions -> Publication -> Custom UI.
            reloadBindings()
        }
    }
    
    func reloadBindings() {
        let message: ConfigMessage =
            ConfigSIGModelAppGet(of: model) ??
            ConfigVendorModelAppGet(of: model)!
        send(message, description: "Reading Bound Application Keys...")
    }
    
    func reloadPublication() {
        guard let message = ConfigModelPublicationGet(for: model) else {
            return
        }
        send(message, description: "Reading Publication settings...")
    }
    
    func reloadSubscriptions() {
        let message: ConfigMessage =
            ConfigSIGModelSubscriptionGet(of: model) ??
            ConfigVendorModelSubscriptionGet(of: model)!
        send(message, description: "Reading Subscriptions...")
    }
    
    func reloadHeartbeatPublication() {
        let message = ConfigHeartbeatPublicationGet()
        send(message, description: "Reading Heartbeat Publication...")
    }
    
    func reloadHeartbeatSubscription() {
        let message = ConfigHeartbeatSubscriptionGet()
        send(message, description: "Reading Heartbeat Subscription...")
    }
    
    /// Sends a message to the mesh network to unbind the given Application Key
    /// from the Model.
    ///
    /// - parameter applicationKey: The Application Key to unbind.
    func unbindApplicationKey(_ applicationKey: ApplicationKey) {
        guard let message = ConfigModelAppUnbind(applicationKey: applicationKey, to: model) else {
            return
        }
        send(message, description: "Unbinding Application Key...")
    }
    
    /// Removes the publication from the model.
    func removePublication() {
        guard let message = ConfigModelPublicationSet(disablePublicationFor: model) else {
            return
        }
        send(message, description: "Removing Publication...")
    }
    
    /// Unsubscribes the Model from publications sent to the given Group.
    ///
    /// - parameter group: The Group to be removed from subscriptions.
    func unsubscribe(from group: Group) {
        let message: ConfigMessage =
            ConfigModelSubscriptionDelete(group: group, from: self.model) ??
            ConfigModelSubscriptionVirtualAddressDelete(group: group, from: self.model)!
        send(message, description: "Unsubscribing...")
    }
    
    /// Removes the Heartbeat publication.
    func removeHeartbeatPublication() {
        let message = ConfigHeartbeatPublicationSet()
        send(message, description: "Cancelling Heartbeat Publications...")
    }
    
    /// Removes the Heartbeat subscription.
    func removeHeartbeatSubscription() {
        let message = ConfigHeartbeatSubscriptionSet()
        send(message, description: "Cancelling Heartbeat Subscription...")
    }
    
}

extension ModelViewController: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didReceiveMessage message: MeshMessage,
                            sentFrom source: Address, to destination: Address) {
        // Has the Node been reset remotely.
        guard !(message is ConfigNodeReset) else {
            (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
            done() {
                self.navigationController?.popToRootViewController(animated: true)
            }
            return
        }
        // Is the message targeting the current Node or Model?
        guard model.parentElement?.unicastAddress == source ||
             (model.parentElement?.parentNode!.unicastAddress == source
                && message is ConfigMessage) else {
            return
        }
        
        // Handle the message based on its type.
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
            // If the Model is being refreshed, the Bindings, Subscriptions
            // and Publication has been read. If the Model has custom UI,
            // try refreshing it as well.
            if let cell = modelViewCell, isRefreshing, cell.startRefreshing() {
                break
            }
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
        
        // Heartheat configuration (only for Configuration Server model)
        case let status as ConfigHeartbeatPublicationStatus:
            if status.isSuccess {
                tableView.reloadSections(.publication, with: .automatic)
                if isRefreshing {
                    reloadHeartbeatSubscription()
                } else {
                    done()
                }
            } else {
               done() {
                   self.presentAlert(title: "Error", message: status.message)
                   self.refreshControl?.endRefreshing()
               }
            }
            
       case let status as ConfigHeartbeatSubscriptionStatus:
           if status.isSuccess {
               tableView.reloadSections(.subscriptions, with: .automatic)
               if isRefreshing {
                _ = modelViewCell?.startRefreshing()
               } else {
                   done()
               }
           } else {
              done() {
                  self.presentAlert(title: "Error", message: status.message)
                  self.refreshControl?.endRefreshing()
              }
          }
            
        // Custom UI
        default:
            let isMore = modelViewCell?.meshNetworkManager(manager, didReceiveMessage: message,
                                                           sentFrom: source, to: destination) ?? false
            if !isMore {
                done()
                
                if let status = message as? StatusMessage, !status.isSuccess {
                    presentAlert(title: "Error", message: status.message)
                } else {
                    if model.isConfigurationServer {
                        tableView.reloadSections(.configurationServer, with: .automatic)
                    }
                }
                refreshControl?.endRefreshing()
            }
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didSendMessage message: MeshMessage,
                            from localElement: Element, to destination: Address) {
        // Has the Node been reset remotely.
        guard !(message is ConfigNodeReset) else {
            (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
            navigationController?.popToRootViewController(animated: true)
            return
        }
        
        switch message {
        case is ConfigMessage:
            // Ignore.
            break
            
        default:
            let isMore = modelViewCell?.meshNetworkManager(manager, didSendMessage: message,
                                                           from: localElement, to: destination) ?? false
            if !isMore {
                done()
            }
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            failedToSendMessage message: MeshMessage,
                            from localElement: Element, to destination: Address,
                            error: Error) {
        done() {
            self.presentAlert(title: "Error", message: error.localizedDescription)
            self.refreshControl?.endRefreshing()
        }
    }
    
}

extension ModelViewController: BindAppKeyDelegate, PublicationDelegate,
                               SubscriptionDelegate, HeartbeatSubscriptionDelegate {
    
    func keyBound() {
        tableView.reloadSections(.bindings, with: .automatic)
    }
    
    func publicationChanged() {
        tableView.reloadSections(.publication, with: .automatic)
    }
    
    func subscriptionAdded() {
        tableView.reloadSections(.subscriptions, with: .automatic)
    }
    
    func heartbeatSubscriptionSet() {
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
    static let configurationServerSection = 1
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
    
    var isConfigurationServer: Bool {
        return section == IndexPath.configurationServerSection
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
    static let configurationServer = IndexSet(integer: IndexPath.configurationServerSection)
    static let custom = IndexSet(integer: IndexPath.subscribeSection + 1)
    
}

private extension Model {
    
    var hasCustomUI: Bool {
        return !isBluetoothSIGAssigned   // Vendor Movels.
            || modelIdentifier == 0x1000 // Generic On Off Server.
            || modelIdentifier == 0x1002 // Generic Level Server.
    }
    
}
