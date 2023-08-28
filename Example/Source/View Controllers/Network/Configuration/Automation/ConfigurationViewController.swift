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
import nRFMeshProvision

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
        self.node = node
        
        // If the Default TLL was known for the original node, set the same value.
        if let ttl = originalNode.defaultTTL {
            tasks.append(.setDefaultTtl(ttl))
        }
        // Do the same for Secure Network beacons, ...
        if let secureNetworkBeacon = originalNode.secureNetworkBeacon {
            tasks.append(.setBeacon(enabled: secureNetworkBeacon))
        }
        // ...Network Transmit, ...
        if let networkTransmit = originalNode.networkTransmit {
            tasks.append(.setNetworkTransit(networkTransmit))
        }
        // ... and the node features:
        switch originalNode.features?.relay {
        case .enabled:
            if let relayRetransmit = originalNode.relayRetransmit {
                tasks.append(.setRelay(relayRetransmit))
            }
        case .notEnabled:
            tasks.append(.disableRelayFeature)
        default:
            break
        }
        
        switch originalNode.features?.proxy {
        case .enabled:
            tasks.append(.setGATTProxy(enabled: true))
        case .notEnabled:
            tasks.append(.setGATTProxy(enabled: false))
        default:
            break
        }
        
        switch originalNode.features?.friend {
        case .enabled:
            tasks.append(.setFriend(enabled: true))
        case .notEnabled:
            tasks.append(.setFriend(enabled: false))
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
                tasks.append(.sendNetworkKey(networkKey))
            }
        }
        meshNetwork.applicationKeys.knownTo(node: originalNode).forEach { applicationKey in
            if !node.knows(applicationKey: applicationKey) {
                tasks.append(.sendApplicationKey(applicationKey))
            }
        }
        
        // With the Network Keys sent we could set the Node Identity state for each of the
        // subnetworks, but the state of Node Identity for Network Keys is dynamic and not
        // stored in the Configuration Database. Therefore, we skip this configuration.
    
        // Set Heartbeat Publication. Only the feature-triggered settings will be applied.
        if let publication = originalNode.heartbeatPublication,
           let networkKey = meshNetwork.networkKeys[publication.networkKeyIndex] {
            tasks.append(.setHeartbeatPublication(
                // Current periodic publication data are not known. Periodic heartbeats will be disabled.
                countLog: 0, periodLog: 0,
                // Set the remaining fields to match the Heartbeat publication of the old node.
                destination: publication.address, ttl: publication.ttl,
                networkKey: networkKey, triggerFeatures: publication.features))
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
                        .filter { originalModel.isBoundTo($0) }
                    boundApplicationKeys.forEach { applicationKey in
                        tasks.append(.bind(applicationKey, to: targetModel))
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
                    tasks.append(.setPublication(newPublication, to: targetModel))
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
                            tasks.append(.subscribe(targetModel, to: group))
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
                tasks.append(.setPublication(newPublication, to: model))
            }
        }
    }
    
    func bind(applicationKeys: [ApplicationKey], to models: [Model]) {
        guard let node = models.first?.parentElement?.parentNode else {
            return
        }
        self.node = node
        // Missing Application Keys must be sent first.
        var networkKeys: [NetworkKey] = []
        applicationKeys.forEach { applicationKey in
            // If a new Application Key is found...
            if !node.knows(applicationKey: applicationKey) {
                // ...check whether the device knows the bound Network Key.
                let networkKey = applicationKey.boundNetworkKey
                if !networkKeys.contains(networkKey) && !node.knows(networkKey: networkKey) {
                    // If not, first send the Network Key.
                    tasks.append(.sendNetworkKey(networkKey))
                    // Do it only once per Network Key.
                    networkKeys.append(networkKey)
                }
                // After the bound Network Key is sent, send the App Key.
                tasks.append(.sendApplicationKey(applicationKey))
            }
        }
        // When all the keys are sent, start binding them to Models.
        models.forEach { model in
            applicationKeys.forEach { applicationKey in
                if !model.isBoundTo(applicationKey) {
                    tasks.append(.bind(applicationKey, to: model))
                }
            }
        }
    }
    
    func subscribe(models: [Model], to groups: [Group]) {
        guard let node = models.first?.parentElement?.parentNode else {
            return
        }
        self.node = node
        models.forEach { model in
            groups.forEach { group in
                if !model.isSubscribed(to: group) {
                    tasks.append(.subscribe(model, to: group))
                }
            }
        }
    }
    
    func set(publication publish: Publish, to models: [Model]) {
        guard let node = models.first?.parentElement?.parentNode else {
            return
        }
        guard let network = MeshNetworkManager.instance.meshNetwork,
              let applicationKey = network.applicationKeys[publish.index] else {
            // Abort.
            return
        }
        self.node = node
        
        // Does the Node know the selected Application Key?
        if !node.knows(applicationKey: applicationKey) {
            // At least the Network Key?
            if !node.knows(networkKeyIndex: applicationKey.boundNetworkKeyIndex),
               let networkKey = network.networkKeys[applicationKey.boundNetworkKeyIndex] {
                tasks.append(.sendNetworkKey(networkKey))
            }
            tasks.append(.sendApplicationKey(applicationKey))
        }
        // For each selected Model...
        models.forEach { model in
            // ...check if it is bound to that Application Key.
            if !model.isBoundTo(applicationKey) {
                // If not, bind it.
                tasks.append(.bind(applicationKey, to: model))
            }
            // and send the Publication.
            tasks.append(.setPublication(publish, to: model))
        }
    }
    
    // MARK: - Private properties
    
    private var node: Node!
    private var tasks: [MeshTask] = []
    private var statuses: [MeshTaskStatus]!
    private var handler: MessageHandle?
    private var inProgress: Bool = true
    private var current: Int = -1
    
    /// The timer firest every second and refreshes the time and remaining time.
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

extension ConfigurationViewController: UITableViewDelegate {
    
}

extension ConfigurationViewController: UITableViewDataSource {
    
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
        
        let current = current
        
        // Are we done?
        if current >= tasks.count || !inProgress {
            handler = nil
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
        // Skip application keys if a network key was not sent.
        case .sendApplicationKey(let applicationKey):
            skipped = !node.knows(networkKey: applicationKey.boundNetworkKey)
        // Skip binding models to Application Keys not known to the Node.
        case .bind(let applicationKey, to: _):
            skipped = !node.knows(applicationKey: applicationKey)
        // Skip publication with keys that failed to be sent.
        case .setPublication(let publish, to: _):
            skipped = !node.knows(applicationKeyIndex: publish.index)
        default:
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
            let manager = MeshNetworkManager.instance
            switch task {
            // Publication Set message can be sent to a different node in some cases.
            case .setPublication(_, to: let model):
                guard let address = model.parentElement?.parentNode?.primaryUnicastAddress else {
                    fallthrough
                }
                handler = try manager.send(task.message, to: address)
            default:
                handler = try manager.send(task.message, to: node.primaryUnicastAddress)
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
        let current = current
        if current >= 0 && current < tasks.count &&
           message.opCode == tasks[current].message.responseOpCode {
            if let status = message as? ConfigStatusMessage {
                reload(taskAt: current, with: .resultOf(status))
                DispatchQueue.main.async {
                    if status.isSuccess {
                        self.progress.addSuccess()
                    } else {
                        self.progress.addFail()
                    }
                }
            } else {
                self.reload(taskAt: current, with: .success)
                DispatchQueue.main.async {
                    self.progress.addSuccess()
                }
            }
            
            executeNext()
        }
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
