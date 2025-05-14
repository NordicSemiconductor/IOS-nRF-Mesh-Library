/*
* Copyright (c) 2023, Nordic Semiconductor
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
import NordicMesh
import iOSMcuManagerLibrary

class ConfigurationViewController: UIViewController,
                                   UIAdaptivePresentationControllerDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var statusView: UILabel!
    @IBOutlet weak var progress: MulticolorProgressView!
    
    @IBOutlet weak var remainingTime: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true)
    }
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        if let handler = handler {
            // Mark all not started tasks as cancelled.
            for i in current + 1..<statuses.count {
                statuses[i] = .cancelled
            }
            handler.cancel()
            return
        }
        navigationController?.dismiss(animated: true)
    }
    
    // MARK: - Public properties
    
    func configure(node: Node, basedOn originalNode: Node) {
        // If the Default TLL was known for the original node, set the same value.
        if let ttl = originalNode.defaultTTL {
            tasks.append(.config(.setDefaultTtl(ttl, on: node)))
        }
        // Do the same for Secure Network beacons, ...
        if let secureNetworkBeacon = originalNode.secureNetworkBeacon {
            tasks.append(.config(.setBeacon(enabled: secureNetworkBeacon, on: node)))
        }
        // ...Network Transmit, ...
        if let networkTransmit = originalNode.networkTransmit {
            tasks.append(.config(.setNetworkTransmit(networkTransmit, on: node)))
        }
        // ... and the node features:
        switch originalNode.features?.relay {
        case .enabled:
            if let relayRetransmit = originalNode.relayRetransmit {
                tasks.append(.config(.setRelay(relayRetransmit, on: node)))
            }
        case .notEnabled:
            tasks.append(.config(.disableRelayFeature(on: node)))
        default:
            break
        }
        
        switch originalNode.features?.proxy {
        case .enabled:
            tasks.append(.config(.setGATTProxy(enabled: true, on: node)))
        case .notEnabled:
            tasks.append(.config(.setGATTProxy(enabled: false, on: node)))
        default:
            break
        }
        
        switch originalNode.features?.friend {
        case .enabled:
            tasks.append(.config(.setFriend(enabled: true, on: node)))
        case .notEnabled:
            tasks.append(.config(.setFriend(enabled: false, on: node)))
        default:
            break
        }
        
        // Here we can't use `originalNode.networkKeys` or `originalNode.applicationKeys`,
        // as the node was already removed from the network. However, we can check which keys
        // of the network were known to that node using the API that those properties use
        // internally.
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        meshNetwork.networkKeys.knownTo(node: originalNode).forEach { networkKey in
            if !node.knows(networkKey: networkKey) {
                tasks.append(.config(.sendNetworkKey(networkKey, to: node)))
            }
        }
        meshNetwork.applicationKeys.knownTo(node: originalNode).forEach { applicationKey in
            if !node.knows(applicationKey: applicationKey) {
                tasks.append(.config(.sendApplicationKey(applicationKey, to: node)))
            }
        }
        
        // With the Network Keys sent we could set the Node Identity state for each of the
        // subnetworks, but the state of Node Identity for Network Keys is dynamic and not
        // stored in the Configuration Database. Therefore, we skip this configuration.
        
        // Set Heartbeat Publication. Only the feature-triggered settings will be applied.
        if let publication = originalNode.heartbeatPublication,
           let networkKey = meshNetwork.networkKeys[publication.networkKeyIndex] {
            tasks.append(.config(.setHeartbeatPublication(
                // Current periodic publication data are not known. Periodic heartbeats will be disabled.
                countLog: 0, periodLog: 0,
                // Set the remaining fields to match the Heartbeat publication of the old node.
                destination: publication.address, ttl: publication.ttl,
                networkKey: networkKey, triggerFeatures: publication.features,
                on: node
            )))
        }
        // Don't set Heartbeat Subscription as the current subscription period of the old Node
        // is not known.
        /*
         if let subscription = originalNode.heartbeatSubscription {
         tasks.append(.setHeartbeatSubscription(
         source: subscription.source, destination: subscription.destination,
         // The period for Heartbeat subscriptions is not known.
         periodLog: 0))
         }
         */
        
        // Key bindings.
        for i in 0..<min(originalNode.elements.count, node.elements.count) {
            let originalElement = originalNode.elements[i]
            let targetElement = node.elements[i]
            
            originalElement.models.forEach { originalModel in
                if originalModel.supportsApplicationKeyBinding,
                   let targetModel = targetElement.model(withModelId: originalModel.modelId) {
                    let boundApplicationKeys = meshNetwork.applicationKeys
                        .filter { $0.isBound(to: originalModel) }
                    boundApplicationKeys.forEach { applicationKey in
                        tasks.append(.config(.bind(applicationKey, to: targetModel)))
                    }
                }
            }
        }
        
        // Model Publications.
        for i in 0..<min(originalNode.elements.count, node.elements.count) {
            let originalElement = originalNode.elements[i]
            let targetElement = node.elements[i]
            
            originalElement.models.forEach { originalModel in
                if originalModel.supportsModelPublication ?? true,
                   let publication = originalModel.publish,
                   let targetModel = targetElement.model(withModelId: originalModel.modelId),
                   let applicationKey = meshNetwork.applicationKeys[publication.index] {
                    // If the Node was publishing to its own Unicast Address, translate it to the new address.
                    let destination = translate(address: publication.publicationAddress, from: originalNode, to: node)
                    let newPublication = Publish(to: destination,
                                                 using: applicationKey,
                                                 usingFriendshipMaterial: publication.isUsingFriendshipSecurityMaterial,
                                                 ttl: publication.ttl,
                                                 period: publication.period,
                                                 retransmit: publication.retransmit)
                    tasks.append(.config(.setPublication(newPublication, to: targetModel)))
                }
            }
        }
        
        // Subscriptions.
        let subscribableGroups = meshNetwork.groups + Group.specialGroups
            .filter { $0 != .allNodes }
        for i in 0..<min(originalNode.elements.count, node.elements.count) {
            let originalElement = originalNode.elements[i]
            let targetElement = node.elements[i]
            
            originalElement.models.forEach { originalModel in
                if originalModel.supportsModelSubscriptions ?? true,
                   let targetModel = targetElement.model(withModelId: originalModel.modelId) {
                    // We can't use `originalModel.subscriptions` as the original node is no longer
                    // a part of the network. Instead, let's filter the groups.
                    subscribableGroups
                        .filter { group in originalModel.isSubscribed(to: group) }
                        .forEach { group in
                            tasks.append(.config(.subscribe(targetModel, to: group)))
                        }
                }
            }
        }
        
        // Reconfigure other Nodes that may be publishing to the previous address of the Node.
        let modelsForReconfiguration = meshNetwork.nodes
            .filter { $0 != node }
            .flatMap { $0.elements }
            .flatMap { $0.models }
            .filter { model in
                if let publicationAddress = model.publish?.publicationAddress.address {
                    return originalNode.contains(elementWithAddress: publicationAddress)
                }
                return false
            }
        modelsForReconfiguration.forEach { model in
            if let publication = model.publish,
               let applicationKey = meshNetwork.applicationKeys[publication.index] {
                let destination = translate(address: publication.publicationAddress, from: originalNode, to: node)
                let newPublication = Publish(to: destination,
                                             using: applicationKey,
                                             usingFriendshipMaterial: publication.isUsingFriendshipSecurityMaterial,
                                             ttl: publication.ttl,
                                             period: publication.period,
                                             retransmit: publication.retransmit)
                tasks.append(.config(.setPublication(newPublication, to: model)))
            }
        }
    }
    
    func bind(applicationKeys: [ApplicationKey], to models: [Model]) {
        // Missing Application Keys must be sent first.
        var cache: [Node: [ApplicationKey]] = [:]
        
        models.forEach { model in
            applicationKeys.forEach { applicationKey in
                if let node = model.parentElement?.parentNode {
                    // If a new Application Key is found...
                    if cache[node]?.contains(applicationKey) != true &&
                        !node.knows(applicationKey: applicationKey) {
                        // ...check whether the device knows the bound Network Key.
                        let networkKey = applicationKey.boundNetworkKey
                        if !node.knows(networkKey: networkKey) {
                            // If not, first send the Network Key.
                            tasks.append(.config(.sendNetworkKey(networkKey, to: node)))
                        }
                        // After the bound Network Key is sent, send the App Key.
                        tasks.append(.config(.sendApplicationKey(applicationKey, to: node)))
                        
                        // Add the Application Key to the cache, so that the same Network Key
                        // and Application Key are not sent multiple times to the same Node.
                        if cache[node] == nil {
                            cache[node] = [applicationKey]
                        } else {
                            cache[node]!.append(applicationKey)
                        }
                    }
                    if !applicationKey.isBound(to: model) {
                        tasks.append(.config(.bind(applicationKey, to: model)))
                    }
                }
            }
        }
    }
    
    func subscribe(models: [Model], to groups: [Group]) {
        models.forEach { model in
            groups.forEach { group in
                if !model.isSubscribed(to: group) {
                    tasks.append(.config(.subscribe(model, to: group)))
                }
            }
        }
    }
    
    func set(publication publish: Publish, to models: [Model]) {
        guard let network = MeshNetworkManager.instance.meshNetwork,
              let applicationKey = network.applicationKeys[publish.index] else {
            // Abort.
            return
        }
        // Missing Application Keys must be sent first.
        var cache: [Node] = []
        
        // For each selected Model...
        models.forEach { model in
            if let node = model.parentElement?.parentNode {
                // If a new Application Key is found...
                if !cache.contains(node) &&
                    !node.knows(applicationKey: applicationKey) {
                    // ...check whether the device knows the bound Network Key.
                    let networkKey = applicationKey.boundNetworkKey
                    if !node.knows(networkKey: networkKey) {
                        // If not, first send the Network Key.
                        tasks.append(.config(.sendNetworkKey(networkKey, to: node)))
                    }
                    // After the bound Network Key is sent, send the App Key.
                    tasks.append(.config(.sendApplicationKey(applicationKey, to: node)))
                    
                    // Add the Application Key to the cache, so that the same Network Key
                    // and Application Key are not sent multiple times to the same Node.
                    cache.append(node)
                }
            }
            
            // ...check if it is bound to that Application Key.
            if !applicationKey.isBound(to: model) {
                // If not, bind it.
                tasks.append(.config(.bind(applicationKey, to: model)))
            }
            // and send the Publication.
            tasks.append(.config(.setPublication(publish, to: model)))
        }
    }
    
    /// Creates operations necessary to update the firmware on the given receivers.
    ///
    /// - note: See [documentation](https://docs.nordicsemi.com/bundle/ncs-latest/page/nrf/protocols/bt/bt_mesh/dfu_over_bt_mesh.html).
    /// - parameters:
    ///  - receivers: The receivers to update.
    ///  - updatePackage: The update package to use.
    ///  - transferMode: The transfer mode to use.
    ///  - policy: The firmware update policy to use.
    ///  - ttl: The TTL value to use.
    ///  - timeoutBase: The timeout base to use.
    ///  - multicast: Optional multicast Group. If `nil`, messages will be sent
    ///               to the Unicast Address of the receiver.
    ///  - applicationKey: The Application Key to use for update messages.
    ///  - distributor: The distributor Node.
    ///  - bearer: A direct bearer to the Distributor Node. This is required to upload the update package
    ///            over SMP protocol.
    func update(receivers: [Receiver], with updatePackage: UpdatePackage,
                withTransferMode transferMode: TransferMode, policy: FirmwareUpdatePolicy,
                ttl: UInt8, timeoutBase: UInt16, multicast: Group?,
                andApplicationKey applicationKey: ApplicationKey,
                on distributor: Node, over bearer: GattBearer) {
        // The Distributor Node must have the Firmware Distribution Server Model.
        guard let meshNetwork = MeshNetworkManager.instance.meshNetwork,
              let firmwareDistributorServerModel = distributor
            .models(withSigModelId: .firmwareDistributionServerModelId)
            .first else {
            return
        }
        
        // Before starting the DFU we need to bind the selected Application Key
        // to the BLOB Transfer Server models and Firmware Update Server models.
        // The Firmware Update Server models have already been bound to the
        // key on the previous screen, where there user was using it to check
        // metadata compatibility, so below we list only BLOB Transfer Server models.
        // Moreover, if a multicast distribution was selected, both Firmware Update Server
        // and BLOB Transfer Server models must be subscribed to the selected group.
        // However, as those models are related, it is enough to subscribe the
        // BLOB Transfer Server models, which we have already listed.
        
        // List BLOB Transfer Server models that are on the
        // same Element as the Firmware Update Server model.
        let models = receivers
            // Convert Receivers to Nodes
            .compactMap { receiver in meshNetwork.node(withAddress: receiver.address) }
            // Look for Firmware Update Server models.
            .flatMap { node in node.models(withSigModelId: .firmwareUpdateServerModelId) }
            // ...and list their Elements.
            .map { firmwareUpdateServerModel in firmwareUpdateServerModel.parentElement! }
            // List BLOB Transfer Server models on those Elements.
            .flatMap { element in
                element.models.filter {
                    $0.isBluetoothSIGAssigned && $0.modelIdentifier == .blobTransferServerModelId
                }
            }
        
        // Bind all found BLOB Transfer Server models to the selected Application Key.
        bind(applicationKeys: [applicationKey], to: models)
        // If a Multicast destination is selected, subscribe to it.
        if let group = multicast {
            subscribe(models: models, to: [group])
        }
        
        // Let's start by adding Receivers. The number of receivers
        // is limited to 10 per message. The maximum number is also ensured by the
        // previous screen, which didn't allow selecting more than Distributor's limit.
        // As Back button is enabled, and the user can go back to modify the list of
        // Receivers, we need to clear the list of receivers first.
        tasks.append(.other(.clearDfuReceivers(from: firmwareDistributorServerModel)))
        let chunks = receivers.chunked(by: 10)
        chunks.forEach { receivers in
            tasks.append(.other(.addDfuReceivers(receivers, to: firmwareDistributorServerModel)))
        }
        
        // Hide Cancel button and replace it with Back.
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem?.title = "Next"
    }
    
    // MARK: - Private properties
    
    private var tasks: [MeshTask] = []
    private var statuses: [MeshTaskStatus]!
    private var handler: MessageHandle?
    private var inProgress: Bool = true
    private var current: Int = -1
    
    /// The timer fires every second and refreshes the time and remaining time.
    private var timer: Timer!
    /// The timestamp when the configuration has started.
    private var startDate: Date!
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make the dialog modal (non-dismissable).
        navigationController?.presentationController?.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // Initially, set all statuses to "pending".
        statuses = tasks.map { _ in .pending }
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // Allow dismiss only when all tasks are complete.
        return !inProgress
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = tasks.isEmpty
        navigationItem.leftBarButtonItem?.isEnabled = !tasks.isEmpty
        progress.isHidden = tasks.isEmpty
        progress.setMax(tasks.count)
        time.isHidden = tasks.isEmpty
        remainingTime.isHidden = tasks.isEmpty
        
        if tasks.isEmpty {
            statusView.text = "The node is already configured."
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !tasks.isEmpty {
            startDate = Date()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                guard let self = self, self.inProgress else {
                    timer.invalidate()
                    return
                }
                let current = self.current
                guard current > 0 else {
                    return
                }
                let elapsedTime = Date().timeIntervalSince(self.startDate)
                let minutes = floor(elapsedTime / 60)
                let seconds = floor(elapsedTime - minutes * 60)
                
                let avgTime = elapsedTime / Double(current)
                let eta = Double(self.tasks.count) * avgTime - elapsedTime
                let remainingMinutes = floor(eta / 60)
                let remainingSeconds = floor(eta - remainingMinutes * 60)
                
                DispatchQueue.main.async {
                    self.time.text = String(format: "%02d:%02d", Int(minutes), Int(seconds))
                    self.remainingTime.text = String(format: "-%02d:%02d", Int(remainingMinutes), Int(remainingSeconds))
                }
            }
            MeshNetworkManager.instance.delegate = self
            executeNext()
        }
        
    }
    
}

extension ConfigurationViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "task", for: indexPath)
        cell.textLabel?.text = tasks[indexPath.row].title
        cell.imageView?.image = tasks[indexPath.row].icon
        let status = statuses[indexPath.row]
        cell.detailTextLabel?.text = status.description
        cell.detailTextLabel?.textColor = status.color
        if case .inProgress = status {
            if #available(iOS 13.0, *) {
                let indicator = UIActivityIndicatorView(style: .medium)
                indicator.startAnimating()
                cell.accessoryView = indicator
            } else {
                let indicator = UIActivityIndicatorView(style: .gray)
                indicator.startAnimating()
                cell.accessoryView = indicator
            }
        } else {
            cell.accessoryView = nil
        }
        return cell
    }
    
}

private extension ConfigurationViewController {
    
    /// Translates the address of an Element on the old Node to the same Element on the new Node.
    ///
    /// If the address is not an address of an Element on the old Node, this method returns it
    /// without modification.
    ///
    /// - parameters:
    ///   - address: The address to translate.
    ///   - oldNode: The old Node instance.
    ///   - newNode: The new Node instance.
    /// - returns: The translated mesh address.
    func translate(address: MeshAddress, from oldNode: Node, to newNode: Node) -> MeshAddress {
        if oldNode.contains(elementWithAddress: address.address) {
            return MeshAddress(newNode.primaryUnicastAddress + address.address - oldNode.primaryUnicastAddress)
        }
        return address
    }
    
    func executeNext() {
        current += 1
        handler = nil
        
        let current = current
        
        // Are we done?
        if current >= tasks.count || !inProgress {
            inProgress = false
            completed()
            return
        }
        
        // Display the title of the current task.
        reload(taskAt: current, with: .inProgress)
        
        // Pop new task and execute.
        let task = tasks[current]
        
        var skipped: Bool!
        switch task {
        case .config(let meshTask):
            switch meshTask {
                // Skip application keys if a network key was not sent.
            case .sendApplicationKey(let applicationKey, to: let node):
                skipped = !node.knows(networkKey: applicationKey.boundNetworkKey)
                // Skip binding models to Application Keys not known to the Node.
            case .bind(let applicationKey, to: let model):
                skipped = !(model.parentElement?.parentNode?.knows(applicationKey: applicationKey) ?? false)
                // Skip publication with keys that failed to be sent.
            case .setPublication(let publish, to: let model):
                skipped = !(model.parentElement?.parentNode?.knows(applicationKeyIndex: publish.index) ?? false)
            default:
                skipped = false
            }
        case .other(let meshTask):
            switch meshTask {
            case .clearDfuReceivers, .addDfuReceivers:
                // If at least one configuration task for DFU task failed, abort.
                skipped = statuses.hasAnyFailed
            }
            skipped = false
        }
        
        guard !skipped else {
           reload(taskAt: current, with: .skipped)
           DispatchQueue.main.async {
               self.progress.addSkipped()
           }
           executeNext()
           return
        }
        
        // Send the message.
        do {
            switch task {
            case .config(let meshTask):
                handler = try MeshNetworkManager.instance.send(meshTask.message, to: meshTask.target)
            case .other(let meshTask):
                handler = try MeshNetworkManager.instance.send(meshTask.message, to: meshTask.target)
            }
        } catch {
            reload(taskAt: current, with: .failed(error))
        }
    }
    
    func reload(taskAt index: Int, with status: MeshTaskStatus) {
        DispatchQueue.main.async {
            self.statusView.text = self.tasks[index].title
            self.statuses[index] = status
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        }
    }
    
    func completed() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.statusView.text = "Configuration complete"
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            self.navigationItem.leftBarButtonItem?.isEnabled = false
            self.remainingTime.isHidden = true
        }
    }
    
}

extension ConfigurationViewController: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didReceiveMessage message: MeshMessage,
                            sentFrom source: Address,
                            to destination: MeshAddress) {
        if let status = message as? StatusMessage {
            reload(taskAt: current, with: .resultOf(status))
            DispatchQueue.main.async {
                if status.isSuccess {
                    self.progress.addSuccess()
                } else {
                    self.progress.addFail()
                }
            }
        } else {
            reload(taskAt: current, with: .success)
            DispatchQueue.main.async {
                self.progress.addSuccess()
            }
        }
        executeNext()
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            failedToSendMessage message: MeshMessage,
                            from localElement: Element,
                            to destination: MeshAddress,
                            error: Error) {
        inProgress = false
        reload(taskAt: current, with: .failed(error))
        completed()
    }
    
}
