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

private enum Section: String {
    case details = "Model Information"
    case configurationServer = "Relay Count & Interval"
    case appKeyBinding = "Bound Application Keys"
    case publication = "Publication"
    case subscriptions = "Subscriptions"
    case heartbeatPublication = "Heartbeat Publication"
    case heartbeatSubscription = "Heartbeat Subscriptions"
    case sensors = "Sensor Values"
    case custom = "Control"
    
    var title: String {
        return rawValue
    }
}

class ModelViewController: ProgressViewController {

    // MARK: - Properties
    
    var model: Model!
    
    private weak var modelViewCell: ModelViewCell?
    private var currentMessage: MeshMessage?
    
    private var heartbeatPublicationCount: RemainingHeartbeatPublicationCount?
    private var heartbeatPublicationFeatures: NodeFeatures?
    private var heartbeatSubscriptionStatus: ConfigHeartbeatSubscriptionStatus?
    
    /// Sensor values are defined only for Sensor Server model,
    /// and only when the value has been read.
    private var sensorValues: [SensorValue]?
    /// Node Identity values per Network Key. Pull to Refresh current states.
    private var nodeIdentityStates: [(key: NetworkKey, state: NodeIdentityState?)]!
    /// This is a helper counter to iterate over Node Identity states while
    /// loading them from the Node. It is reinitialized to 0 on Pull To Refresh
    /// and incremented with every status received until all identity states are
    /// received.
    private var identityIndex = 0
    
    private var sections: [Section] = []
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = model.name ?? "Model"
        
        // Details section is always visible.
        sections.append(.details)
        // Add additional sections, based on the Model.
        if model.supportsApplicationKeyBinding {
            sections.append(.appKeyBinding)
        }
        if model.supportsModelPublication ?? true {
            sections.append(.publication)
        }
        if model.supportsModelSubscriptions ?? true {
            sections.append(.subscriptions)
        }
        if model.isSensorServer {
            sections.append(.sensors)
        }
        if model.hasCustomUI {
            sections.append(.custom)
        }
        if model.isConfigurationServer {
            sections.append(.configurationServer)
            sections.append(.heartbeatPublication)
            sections.append(.heartbeatSubscription)
            
            // Pull to Refresh will refresh states of the Node Identities per Network Key.
            nodeIdentityStates = model.parentElement?.parentNode?.networkKeys
                .map { networkKey in (networkKey, nil) } ?? []
        }
        // Configuration Client has nothing to Edit.
        if !model.isConfigurationClient {
            navigationItem.rightBarButtonItem = editButtonItem
        }
        // Registed Nibs for Custom UI.
        tableView.register(UINib(nibName: "ConfigurationServer", bundle: nil),
                           forCellReuseIdentifier: UInt16.configurationServerModelId.hex)
        tableView.register(UINib(nibName: "GenericOnOff", bundle: nil),
                           forCellReuseIdentifier: UInt16.genericOnOffServerModelId.hex)
        tableView.register(UINib(nibName: "GenericLevel", bundle: nil),
                           forCellReuseIdentifier: UInt16.genericLevelServerModelId.hex)
        tableView.register(UINib(nibName: "GenericDefaultTransitionTime", bundle: nil),
                           forCellReuseIdentifier: UInt16.genericDefaultTransitionTimeServerModelId.hex)
        tableView.register(UINib(nibName: "GenericPowerOnOff", bundle: nil),
                           forCellReuseIdentifier: UInt16.genericPowerOnOffServerModelId.hex)
        tableView.register(UINib(nibName: "GenericPowerOnOffSetup", bundle: nil),
                           forCellReuseIdentifier: UInt16.genericPowerOnOffSetupServerModelId.hex)
        tableView.register(UINib(nibName: "VendorModel", bundle: nil),
                           forCellReuseIdentifier: "vendor")
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
        if segue.identifier == "related" {
            let destination = segue.destination as! RelatedModelsViewController
            destination.model = model
            return
        }
        let navigationController = segue.destination as? UINavigationController
        navigationController?.presentationController?.delegate = self
        
        switch segue.identifier {
        case "bind":
            let viewController = navigationController?.topViewController as! ModelBindAppKeyViewController
            viewController.model = model
            viewController.delegate = self
        case "heartbeatPublication":
            let viewController = navigationController?.topViewController as! SetHeartbeatPublicationViewController
            viewController.node = model.parentElement!.parentNode!
            viewController.delegate = self
        case "heartbeatSubscription":
            let viewController = navigationController?.topViewController as! SetHeartbeatSubscriptionViewController
            viewController.node = model.parentElement!.parentNode!
            viewController.delegate = self
        case "publish":
            let viewController = navigationController?.topViewController as! SetPublicationViewController
            viewController.model = model
            viewController.delegate = self
        case "subscribe":
            let viewController = navigationController?.topViewController as! SubscribeViewController
            viewController.model = model
            viewController.delegate = self
        default:
            break
        }
    }
    
    // MARK: - Table View Controller
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sections[section]
        switch section {
        case .details:
            return 3
        case .configurationServer:
            return 1 + nodeIdentityStates.count /* Network Keys for Node Identity view */
        case .appKeyBinding:
            return model.boundApplicationKeys.count + 1 // Add Action.
        case .heartbeatPublication:
            if let _ = model.parentElement?.parentNode?.heartbeatPublication {
                return 4 // Destination, Remaining Count, Features, Refresh Action.
            }
            return 1 // Set Publication Action.
        case .publication:
            return 1 // Set Publication Action or the Publication.
        case .heartbeatSubscription:
            if let _ = model.parentElement?.parentNode?.heartbeatSubscription {
                return 6 // Destination, Remaining Period, Count, Min Hops, Max Hops, Refresh Action.
            }
            return 1 // Set Subscription Action.
        case .subscriptions:
            return model.subscriptions.count + 1 // Add Action.
        case .sensors:
            return (sensorValues?.count ?? 0) + 1 // Get Action.
        case .custom:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let localProvisioner = MeshNetworkManager.instance.meshNetwork?.localProvisioner
        
        let section = sections[indexPath.section]
        switch section {
        case .details:
            let cell = tableView.dequeueReusableCell(withIdentifier: "normal", for: indexPath)
            switch indexPath.row {
            case 0: // Model ID
                cell.textLabel?.text = "Model ID"
                cell.detailTextLabel?.text = model.modelIdentifier.asString()
                cell.accessoryType = .none
            case 1: // Company
                cell.textLabel?.text = "Company"
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
                cell.accessoryType = .none
            case 2: // Related Models
                cell.textLabel?.text = "Related Models"
                cell.detailTextLabel?.text = "\(model.relatedModels.count)"
                cell.accessoryType = .disclosureIndicator
            default:
                fatalError()
            }
            return cell
        case .appKeyBinding:
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
        case .configurationServer:
            // For Configuration Server, the first row is a ConfigurationServerViewCell.
            // The last item in this cell is the header for Node Identity,
            // which requires listing all Network Keys. Let's list them here:
            if indexPath.row > 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "switch", for: indexPath) as! SwitchCell
                let identity = nodeIdentityStates[indexPath.row - 1]
                cell.title.text = identity.key.name
                cell.switch.isOn = identity.state == .running
                cell.switch.isEnabled = identity.state != nil && identity.state != .notSupported
                cell.title.isEnabled = identity.state != nil && identity.state != .notSupported
                cell.delegate = { [weak self] newState in
                    self?.identityIndex = indexPath.row - 1
                    self?.setNodeIdentityStatus(for: identity.key, enable: newState)
                }
                return cell
            }
            // The first row of the section is rendered as a Custom section.
            fallthrough
        case .custom:
            // A custom cell for the Model.
            let identifier = model.isBluetoothSIGAssigned ? model.modelIdentifier.hex : "vendor"
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! ModelViewCell
            cell.delegate = self
            cell.model    = model
            modelViewCell = cell
            return cell
        case .heartbeatPublication:
            guard let publication = model.parentElement?.parentNode?.heartbeatPublication else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
                cell.textLabel?.text = "Set Publication"
                cell.textLabel?.isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
                return cell
            }
            switch indexPath.row {
            case 0: // Publication
                let cell = tableView.dequeueReusableCell(withIdentifier: "heartbeatPublication", for: indexPath) as! HeartbeatPublicationCell
                cell.heartbeatPublication = publication
                return cell
            case 1: // Count
                let cell = tableView.dequeueReusableCell(withIdentifier: "normal", for: indexPath)
                cell.textLabel?.text = "Remaining Count"
                cell.detailTextLabel?.text = heartbeatPublicationCount.map { "\($0)" } ?? "Unknown"
                cell.accessoryType = .none
                return cell
            case 2: // Count
                let cell = tableView.dequeueReusableCell(withIdentifier: "normal", for: indexPath)
                cell.textLabel?.text = "Features"
                cell.detailTextLabel?.text = heartbeatPublicationFeatures.map { "\($0)" } ?? "Unknown"
                cell.accessoryType = .none
                return cell
            case 3: // Refresh action
                let cell = tableView.dequeueReusableCell(withIdentifier: "rightAction", for: indexPath) as! RightActionCell
                cell.textLabel?.text = "Refresh"
                cell.isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
                cell.delegate = {
                    self.reloadHeartbeatPublication()
                }
                return cell
            default:
                fatalError()
            }
        case .heartbeatSubscription:
            guard let subscription = model.parentElement?.parentNode?.heartbeatSubscription else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
                cell.textLabel?.text = "Subscribe"
                cell.textLabel?.isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
                return cell
            }
            switch indexPath.row {
            case 0: // Subscription
                let cell = tableView.dequeueReusableCell(withIdentifier: "heartbeatSubscription", for: indexPath) as! HeartbeatSubscriptionCell
                cell.subscription = subscription
                return cell
            case 1: // Remaining Period
                let cell = tableView.dequeueReusableCell(withIdentifier: "normal", for: indexPath)
                cell.textLabel?.text = "Remaining Period"
                if let period = heartbeatSubscriptionStatus?.period {
                    if case .range(let range) = period {
                        cell.detailTextLabel?.text = range.asTime()
                    } else {
                        cell.detailTextLabel?.text = "\(period)"
                    }
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
                cell.accessoryType = .none
                return cell
            case 2: // Count
                let cell = tableView.dequeueReusableCell(withIdentifier: "normal", for: indexPath)
                cell.textLabel?.text = "Count"
                cell.detailTextLabel?.text = heartbeatSubscriptionStatus.map { "\($0.count)" } ?? "Unknown"
                cell.accessoryType = .none
                return cell
            case 3: // Min Hops
                let cell = tableView.dequeueReusableCell(withIdentifier: "normal", for: indexPath)
                cell.textLabel?.text = "Min Hops"
                cell.detailTextLabel?.text = heartbeatSubscriptionStatus.map { "\($0.minHops)" } ?? "Unknown"
                cell.accessoryType = .none
                return cell
            case 4: // Max Hops
                let cell = tableView.dequeueReusableCell(withIdentifier: "normal", for: indexPath)
                cell.textLabel?.text = "Max Hops"
                cell.detailTextLabel?.text = heartbeatSubscriptionStatus.map { "\($0.maxHops)" } ?? "Unknown"
                cell.accessoryType = .none
                return cell
            case 5: // Refresh action
                let cell = tableView.dequeueReusableCell(withIdentifier: "rightAction", for: indexPath) as! RightActionCell
                cell.textLabel?.text = "Refresh"
                cell.isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
                cell.delegate = {
                    self.reloadHeartbeatSubscription()
                }
                return cell
            default:
                fatalError("Too many rows in Heartbeat publication section: \(indexPath)")
            }
        case .publication:
            guard let publish = model.publish else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
                cell.textLabel?.text = "Set Publication"
                cell.textLabel?.isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "destination", for: indexPath) as! PublicationCell
            cell.publish = publish
            return cell
        case .subscriptions:
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
        case .sensors:
            guard let sensorValues = sensorValues,
                  indexPath.row < sensorValues.count else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
                cell.textLabel?.text = "Get"
                cell.textLabel?.isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "value", for: indexPath) as! SensorValueCell
            cell.value = sensorValues[indexPath.row]
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let localProvisioner = MeshNetworkManager.instance.meshNetwork?.localProvisioner
        guard localProvisioner?.hasConfigurationCapabilities ?? false else {
            return false
        }
        
        let section = sections[indexPath.section]
        switch section {
        case .details:
            return indexPath.row == 2 // Related Models
        case .appKeyBinding:
            return indexPath.row == model.boundApplicationKeys.count
        case .heartbeatPublication, .publication:
            return indexPath.row == 0
        case .heartbeatSubscription:
            return indexPath.row == 0
        case .subscriptions:
            return indexPath.row == model.subscriptions.count
        case .sensors:
            return indexPath.row == sensorValues?.count ?? 0
        case .custom, .configurationServer:
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let section = sections[indexPath.section]
        switch section {
        case .details:
            performSegue(withIdentifier: "related", sender: indexPath)
        case .appKeyBinding:
            performSegue(withIdentifier: "bind", sender: indexPath)
        case .heartbeatPublication:
            performSegue(withIdentifier: "heartbeatPublication", sender: indexPath)
        case .publication:
            guard !model.boundApplicationKeys.isEmpty else {
                presentAlert(title: "Application Key required",
                             message: "Bind at least one Application Key before setting the publication.")
                return
            }
            performSegue(withIdentifier: "publish", sender: indexPath)
        case .heartbeatSubscription:
            performSegue(withIdentifier: "heartbeatSubscription", sender: indexPath)
        case .subscriptions:
            performSegue(withIdentifier: "subscribe", sender: indexPath)
        case .sensors:
            readSensorValues()
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let section = sections[indexPath.section]
        switch section {
        case .appKeyBinding:
            return indexPath.row < model.boundApplicationKeys.count
        case .heartbeatPublication:
            let publication = model.parentElement?.parentNode?.heartbeatPublication
            return indexPath.row == 0 && publication != nil
        case .publication:
            return indexPath.row == 0 && model.publish != nil
        case .heartbeatSubscription:
            let subscription = model.parentElement?.parentNode?.heartbeatSubscription
            return indexPath.row == 0 && subscription != nil
        case .subscriptions:
            return indexPath.row < model.subscriptions.count &&
                   model.subscriptions[indexPath.row].address.address != .allNodes
        default:
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let section = sections[indexPath.section]
        switch section {
        case .appKeyBinding:
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
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        switch section {
        case .heartbeatPublication:
            removeHeartbeatPublication()
        case .publication:
            removePublication()
        case .heartbeatSubscription:
            removeHeartbeatSubscription()
        case .subscriptions:
            let group = model.subscriptions[indexPath.row]
            unsubscribe(from: group)
        default:
            break
        }
    }

}

private extension ModelViewController {
    
    func reloadSections(_ sections: [Section], with animation: UITableView.RowAnimation) {
        DispatchQueue.main.async {
            let indexes = sections.compactMap { self.sections.firstIndex(of: $0) }
            let indexSet = IndexSet(indexes)
            self.tableView.reloadSections(indexSet, with: animation)
        }
    }
    
    func reloadSections(_ section: Section, with animation: UITableView.RowAnimation) {
        reloadSections([section], with: animation)
    }
    
}

extension ModelViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        MeshNetworkManager.instance.delegate = self
    }
    
}

extension ModelViewController: ModelViewCellDelegate {
    
    func send(_ message: MeshMessage, description: String) {
        guard let model = model else {
            return
        }
        currentMessage = message
        start(description) {
            switch message {
            case let request as AcknowledgedMeshMessage:
                return try MeshNetworkManager.instance.send(request, to: model)
            case let command as UnacknowledgedMeshMessage:
                return try MeshNetworkManager.instance.send(command, to: model)
            default:
                return nil
            }
        }
    }
    
    func send(_ message: some AcknowledgedConfigMessage, description: String) {
        guard let node = model?.parentElement?.parentNode else {
            return
        }
        currentMessage = message
        start(description) {
            return try MeshNetworkManager.instance.send(message, to: node)
        }
    }
    
    var isRefreshing: Bool {
        return DispatchQueue.main.sync { refreshControl?.isRefreshing ?? false }
    }
    
}

private extension ModelViewController {
    
    @objc func reload(_ sender: Any) {
        switch model! {
        case let model where model.isConfigurationServer:
            // First, load the states of Node Identity for all Network Keys.
            // Start with the first one. At least one Network Key is required.
            identityIndex = 0
            nodeIdentityStates.first.map { key, _ in
                readNodeIdentityStatus(for: key)
            }
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
    
    func readSensorValues() {
        let message = SensorGet()
        send(message, description: "Reading Values...")
    }
    
    func readNodeIdentityStatus(for networkKey: NetworkKey) {
        send(ConfigNodeIdentityGet(networkKey: networkKey),
             description: "Reading Node Identity status for \(networkKey)...")
    }
        
    func setNodeIdentityStatus(for networkKey: NetworkKey, enable: Bool) {
        let message = "\(enable ? "Enabling" : "Disabling") Node Identity for \(networkKey)..."
        send(ConfigNodeIdentitySet(networkKey: networkKey, identity: enable ? .running : .stopped),
             description: message)
    }
    
}

extension ModelViewController: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didReceiveMessage message: MeshMessage,
                            sentFrom source: Address, to destination: Address) {
        // Has the Node been reset remotely.
        guard !(message is ConfigNodeReset) else {
            (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
            done {
                self.navigationController?.popToRootViewController(animated: true)
            }
            return
        }
        // Is the message targeting the current Node or Model?
        guard model.parentElement?.unicastAddress == source ||
             (model.parentElement?.parentNode!.primaryUnicastAddress == source
                && message is ConfigMessage) else {
            return
        }
        
        // Handle the message based on its type.
        switch message {
            
        case let status as ConfigModelAppStatus:
            done()
            
            if status.isSuccess {
                reloadSections([.appKeyBinding, .publication], with: .automatic)
                setEditing(false, animated: true)
            } else {
                presentAlert(title: "Error", message: status.message)
            }
            
        case let list as ConfigModelAppList & StatusMessage:
            if list.isSuccess {
                reloadSections([.appKeyBinding, .publication], with: .automatic)
                if model.supportsModelSubscriptions ?? true {
                    reloadSubscriptions()
                    break
                }
                if model.supportsModelPublication ?? true {
                    reloadPublication()
                    break
                }
                // If both Publications and Subscriptions are not supported,
                // try refreshing custom view.
                if let cell = modelViewCell, isRefreshing, cell.startRefreshing() {
                    break
                }
                done() {
                    self.refreshControl?.endRefreshing()
                }
            } else {
                done {
                    self.presentAlert(title: "Error", message: list.message)
                    self.refreshControl?.endRefreshing()
                }
            }
            
        case let status as ConfigModelSubscriptionStatus:
            done()
            
            if status.isSuccess {
                reloadSections(.subscriptions, with: .automatic)
                setEditing(false, animated: true)
            } else {
                presentAlert(title: "Error", message: status.message)
            }
            
        case let list as ConfigModelSubscriptionList & StatusMessage:
            if list.isSuccess {
                reloadSections(.subscriptions, with: .automatic)
                if model.supportsModelPublication ?? true {
                    reloadPublication()
                    break
                }
                // If Publications are not supported, try refreshing custom view.
                if let cell = modelViewCell, isRefreshing, cell.startRefreshing() {
                    break
                }
                done() {
                    self.refreshControl?.endRefreshing()
                }
            } else {
                done {
                    self.presentAlert(title: "Error", message: list.message)
                    self.refreshControl?.endRefreshing()
                }
            }
            
        case let status as ConfigModelPublicationStatus:
            // If the Model is being refreshed, the Bindings, Subscriptions
            // and Publication has been read. If the Model has custom UI,
            // try refreshing it as well.
            if let cell = modelViewCell, isRefreshing, cell.startRefreshing() {
                break
            }
            done() {
                if status.isSuccess {
                    self.reloadSections(.publication, with: .automatic)
                    self.setEditing(false, animated: true)
                } else {
                    self.presentAlert(title: "Error", message: status.message)
                }
                self.refreshControl?.endRefreshing()
            }
            
        // Node Identity (only for Configuration Server model)
        case let status as ConfigNodeIdentityStatus:
            if status.isSuccess {
                nodeIdentityStates[identityIndex].state = status.identity
                reloadSections(.configurationServer, with: .automatic)
                if isRefreshing {
                    identityIndex += 1
                    if identityIndex < nodeIdentityStates.count {
                        readNodeIdentityStatus(for: nodeIdentityStates[identityIndex].key)
                    } else {
                        // Load heartbeat publication, which will trigger reading
                        // heartbeat subscription, which will load custom UI.
                        reloadHeartbeatPublication()
                    }
                } else {
                    done()
                }
            } else {
                done {
                    self.nodeIdentityStates[self.identityIndex].state = .notSupported
                    self.reloadSections(.configurationServer, with: .automatic)
                    self.presentAlert(title: "Error", message: status.message)
                    self.refreshControl?.endRefreshing()
                }
            }
        
        // Heartbeat configuration (only for Configuration Server model)
        case let status as ConfigHeartbeatPublicationStatus:
            if status.isSuccess {
                heartbeatPublicationCount = status.count
                heartbeatPublicationFeatures = status.features
                reloadSections(.heartbeatPublication, with: .automatic)
                if isRefreshing {
                    reloadHeartbeatSubscription()
                } else {
                    done()
                }
            } else {
               done {
                   self.presentAlert(title: "Error", message: status.message)
                   self.refreshControl?.endRefreshing()
               }
            }
            
        case let status as ConfigHeartbeatSubscriptionStatus:
            if status.isSuccess {
                heartbeatSubscriptionStatus = status
                reloadSections(.heartbeatSubscription, with: .automatic)
                if isRefreshing {
                    _ = modelViewCell?.startRefreshing()
                } else {
                    done()
                }
            } else {
                done {
                    self.presentAlert(title: "Error", message: status.message)
                    self.refreshControl?.endRefreshing()
                }
            }
            
        // Sensor Server
        case let status as SensorStatus:
            sensorValues = status.values
            done {
                self.reloadSections(.sensors, with: .automatic)
            }
            
        // Custom UI
        default:
            guard let cell = modelViewCell, cell.supports(type(of: message)) else {
                break
            }
            let isMore = cell.meshNetworkManager(manager, didReceiveMessage: message,
                                                 sentFrom: source, to: destination)
            if !isMore {
                done {
                    if let status = message as? StatusMessage, !status.isSuccess {
                        self.presentAlert(title: "Error", message: status.message)
                    }
                    self.refreshControl?.endRefreshing()
                }
            }
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didSendMessage message: MeshMessage,
                            from localElement: Element, to destination: Address) {
        guard message.opCode == currentMessage?.opCode else {
            return
        }
        currentMessage = nil
        // If an unacknowledged message was sent, we're done.
        let isAckExpected = message is AcknowledgedMeshMessage
        if !isAckExpected {
            done()
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            failedToSendMessage message: MeshMessage,
                            from localElement: Element, to destination: Address,
                            error: Error) {
        // Ignore messages sent from model publication.
        guard message.opCode == currentMessage?.opCode else {
            return
        }
        currentMessage = nil
        done {
            self.presentAlert(title: "Error", message: error.localizedDescription)
            self.refreshControl?.endRefreshing()
        }
    }
    
}

extension ModelViewController: BindAppKeyDelegate,
                               PublicationDelegate, HeartbeatPublicationDelegate,
                               SubscriptionDelegate, HeartbeatSubscriptionDelegate {
                                   
    func presentNodeApplicationKeys() {
        if let configurationViewController = navigationController?.viewControllers
                .first(where: { $0 is NodeViewController }) {
            navigationController?.popToViewController(configurationViewController, animated: true)
            configurationViewController.performSegue(withIdentifier: "showAppKeys", sender: nil)
        }
    }
    
    func keyBound() {
        reloadSections(.appKeyBinding, with: .automatic)
    }
    
    func publicationChanged() {
        reloadSections(.publication, with: .automatic)
    }
    
    func heartbeatPublicationChanged() {
        reloadSections(.heartbeatPublication, with: .automatic)
    }
    
    func subscriptionAdded() {
        reloadSections(.subscriptions, with: .automatic)
    }
    
    func heartbeatSubscriptionSet() {
        reloadSections(.heartbeatSubscription, with: .automatic)
    }
    
}

private extension Model {
    
    var isConfigurationServer: Bool {
        return isBluetoothSIGAssigned && modelIdentifier == .configurationServerModelId
    }
    
    var isConfigurationClient: Bool {
        return isBluetoothSIGAssigned && modelIdentifier == .configurationClientModelId
    }
    
    var isSensorServer: Bool {
        return isBluetoothSIGAssigned && modelIdentifier == .sensorServerModelId
    }
    
}

private extension Model {
    
    var hasCustomUI: Bool {
        return !isBluetoothSIGAssigned   // Vendor Models.
            || modelIdentifier == .genericOnOffServerModelId
            || modelIdentifier == .genericPowerOnOffServerModelId
            || modelIdentifier == .genericPowerOnOffSetupServerModelId
            || modelIdentifier == .genericLevelServerModelId
            || modelIdentifier == .genericDefaultTransitionTimeServerModelId
    }
    
}

extension NodeFeatures: CustomStringConvertible {
    
    public var description: String {
        guard !isEmpty else {
            return "Disabled"
        }
        var features: [String] = []
        if contains(.relay) {
            features.append("Relay")
        }
        if contains(.proxy) {
            features.append("Proxy")
        }
        if contains(.friend) {
            features.append("Friend")
        }
        if contains(.lowPower) {
            features.append("Low Power")
        }
        return features.joined(separator: ", ")
    }
    
}
