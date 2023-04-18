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
    
    func configure(_ node: Node) {
        self.node = node
        // If the Node's configuration hasn't been read, it's
        // a good time to do that.
        if node.relayRetransmit == nil {
            tasks.append(.readRelayStatus)
        }
        if node.networkTransmit == nil {
            tasks.append(.readNetworkTransitStatus)
        }
        if node.secureNetworkBeacon == nil {
            tasks.append(.readBeaconStatus)
        }
        if node.features?.proxy == nil {
            tasks.append(.readGATTProxyStatus)
        }
        if node.features?.friend == nil {
            tasks.append(.readFriendStatus)
        }
        // The result of reading Heartbeat publication and subscription
        // would not be shown, so skip it.
        // In order to read the current state use Pull to Refresh on
        // Configuration Server model screen.
        /*
        if node.heartbeatPublication == nil {
            tasks.append(.readHeartbeatPublication)
        }
        if node.heartbeatSubscription == nil {
            tasks.append(.readHeartbeatSubscription)
        }
        */
        // The state of Node Identity is not preserved, no need to read it.
        /*
        node.networkKeys.forEach { networkKey in
            tasks.append(.readNodeIdentityStatus(networkKey))
        }
        */
        // If there's no Application Keys, create one.
        let network = MeshNetworkManager.instance.meshNetwork!
        if network.applicationKeys.isEmpty {
            let newApplicationKey = try! network.add(applicationKey: .random128BitKey(), name: "App Key 1")
            if let networkKey = node.networkKeys.first {
                try! newApplicationKey.bind(to: networkKey)
            }
        }
        // Missing Application Keys must be sent first.
        var networkKeys: [NetworkKey] = []
        network.applicationKeys.forEach { applicationKey in
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
        // Bind all Application Keys to all Models.
        let allModels = node.elements
            .flatMap { $0.models }
        allModels
            .filter { $0.supportsApplicationKeyBinding }
            .forEach { model in
                network.applicationKeys.forEach { applicationKey in
                    if !model.isBoundTo(applicationKey) {
                        tasks.append(.bind(applicationKey, to: model))
                    }
                }
            }
        // If there are no Groups, create a normal one, and a virtual one.
        if network.groups.isEmpty {
            try! network.add(group: Group(name: "Normal Group", address: network.nextAvailableGroupAddress()!))
            try! network.add(group: Group(name: "Virtual Group", address: MeshAddress(UUID())))
        }
        // Subscribe all Models to all Groups.
        allModels
            .filter { $0.supportsModelSubscriptions ?? true }
            .forEach { model in
                network.groups.forEach { group in
                    if !model.isSubscribed(to: group) {
                        tasks.append(.subscribe(model, to: group))
                    }
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
    
    // MARK: - Private properties
    
    private var node: Node!
    private var tasks: [Task] = []
    private var statuses: [TaskStatus]!
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
        
        // Skip messages with Application Keys bound to Network Keys
        // that aren't known to the Node.
        if let message = task.message as? ConfigNetAndAppKeyMessage {
            if !node.knows(networkKeyIndex: message.networkKeyIndex) {
                reload(taskAt: current, with: .skipped)
                DispatchQueue.main.async {
                    self.progress.addSkipped()
                }
                executeNext()
                return
            }
        }
        // Skip binding models to Application Keys not known to the Node.
        if let message = task.message as? ConfigModelAppBind {
            if !node.knows(applicationKeyIndex: message.applicationKeyIndex) {
                reload(taskAt: current, with: .skipped)
                DispatchQueue.main.async {
                    self.progress.addSkipped()
                }
                executeNext()
                return
            }
        }
        
        // Send the message.
        do {
            let manager = MeshNetworkManager.instance
            handler = try manager.send(task.message, to: node.primaryUnicastAddress)
        } catch {
            reload(taskAt: current, with: .failed(error))
        }
    }
    
    func reload(taskAt index: Int, with status: TaskStatus) {
        DispatchQueue.main.async {
            self.statusView.text = self.tasks[index].title
            self.statuses[index] = status
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        }
    }
    
    func completed() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.statusView.text = "Configuration complete."
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
                            to destination: Address) {
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
                            to destination: Address,
                            error: Error) {
        inProgress = false
        reload(taskAt: current, with: .failed(error))
        completed()
    }
    
}
