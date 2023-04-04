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

private enum Task {
    case readRelayStatus
    case readNetworkTransitStatus
    case readBeaconStatus
    case readGATTProxyStatus
    case readFriendStatus
    case readNodeIdentityStatus(_ networkKey: NetworkKey)
    case readHeartbeatPublication
    case readHeartbeatSubscription
    
    case sendNetworkKey(_ networkKey: NetworkKey)
    case sendApplicationKey(_ applicationKey: ApplicationKey)
    case bind(_ applicationKey: ApplicationKey, to: Model)
    case subscribe(_ model: Model, to: Group)
    
    var title: String {
        switch self {
        case .readRelayStatus:
            return "Read Relay Status"
        case .readNetworkTransitStatus:
            return "Read Network Transit Status"
        case .readBeaconStatus:
            return "Read Beacon Status"
        case .readGATTProxyStatus:
            return "Read GATT Proxy Status"
        case .readFriendStatus:
            return "Read Friend Status"
        case .readNodeIdentityStatus(let key):
            return "Read Node Identity Status for \(key.name)"
        case .readHeartbeatPublication:
            return "Read Heartbeat Publication"
        case .readHeartbeatSubscription:
            return "Read Heartbeat Subscription"
        case .sendNetworkKey(let key):
            return "Send \(key.name)"
        case .sendApplicationKey(let key):
            return "Send \(key.name)"
        case .bind(let key, to: let model):
            return "Bind \(key.name) to \(model)"
        case .subscribe(let model, to: let group):
            return "Subscribe \(model) to \(group.name)"
        }
    }
    
    var message: AcknowledgedConfigMessage {
        switch self {
        case .readRelayStatus:
            return ConfigRelayGet()
        case .readNetworkTransitStatus:
            return ConfigNetworkTransmitGet()
        case .readBeaconStatus:
            return ConfigBeaconGet()
        case .readGATTProxyStatus:
            return ConfigGATTProxyGet()
        case .readFriendStatus:
            return ConfigFriendGet()
        case .readNodeIdentityStatus(let key):
            return ConfigNodeIdentityGet(networkKey: key)
        case .readHeartbeatPublication:
            return ConfigHeartbeatPublicationGet()
        case .readHeartbeatSubscription:
            return ConfigHeartbeatSubscriptionGet()
        case .sendNetworkKey(let key):
            return ConfigNetKeyAdd(networkKey: key)
        case .sendApplicationKey(let key):
            return ConfigAppKeyAdd(applicationKey: key)
        case .bind(let key, to: let model):
            return ConfigModelAppBind(applicationKey: key, to: model)!
        case .subscribe(let model, to: let group):
            if let message = ConfigModelSubscriptionAdd(group: group, to: model) {
                return message
            } else {
                return ConfigModelSubscriptionVirtualAddressAdd(group: group, to: model)!
            }
        }
    }
}

class ConfigurationViewController: UIViewController,
                                   UIAdaptivePresentationControllerDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var detailsButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var statusView: UILabel!
    @IBOutlet weak var progress: MulticolorProgressView!
    
    @IBOutlet weak var remainingTime: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBAction func doneTapped(_ sender: UIButton) {
        navigationController?.dismiss(animated: true)
    }
    @IBAction func cancelTapped(_ sender: UIButton) {
        if let handler = handler {
            inProgress = false
            cancelButton.titleLabel?.text = "Cancelling..."
            cancelButton.isEnabled = false
            handler.cancel()
            return
        }
        navigationController?.dismiss(animated: true)
    }
    
    @IBAction func detailsTapped(_ sender: UIButton) {
    }
    
    // MARK: - Public properties
    
    func configure(_ node: Node) {
        self.node = node
        // If the Node's configuration hasn't been read, it's
        // a good time to do that.
        if node.features == nil {
            tasks.append(.readRelayStatus)
            tasks.append(.readNetworkTransitStatus)
            tasks.append(.readBeaconStatus)
            tasks.append(.readGATTProxyStatus)
            tasks.append(.readFriendStatus)
            node.networkKeys.forEach { networkKey in
                tasks.append(.readNodeIdentityStatus(networkKey))
            }
            tasks.append(.readHeartbeatPublication)
            tasks.append(.readHeartbeatSubscription)
        }
        // If there's no Application Keys, create one.
        let network = MeshNetworkManager.instance.meshNetwork!
        if network.applicationKeys.isEmpty {
            try! network.add(applicationKey: .random128BitKey(), name: "App Key 1")
        }
        network.applicationKeys.forEach { applicationKey in
            if !node.knows(applicationKey: applicationKey) {
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
        // First missing Application Keys must be sent.
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
    
    // MARK: - Private properties
    
    private var node: Node!
    private var tasks: [Task] = []
    private var handler: MessageHandle?
    private var inProgress: Bool = false
    private var current: Int = -1
    private var responseOpCode: UInt32?
    private var failed: Int = 0
    private var timer: Timer!
    private var startDate: Date!
    
    private var timeFormatter: DateFormatter!
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make the dialog modal (non-dismissable).
        navigationController?.presentationController?.delegate = self
        
        statusView.text = ""
        progress.setMax(tasks.count)
        
        makeBlue(doneButton)
        makeOrange(cancelButton)
        
        timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "mm:ss"
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // Allow dismiss only when all tasks are complete.
        return !inProgress
    }
    
    override func viewWillAppear(_ animated: Bool) {
        doneButton.isHidden = !tasks.isEmpty
        cancelButton.isHidden = tasks.isEmpty
        progress.isHidden = tasks.isEmpty
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
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                if !self.inProgress {
                    timer.invalidate()
                    return
                }
                let elapsedTime = Date().timeIntervalSince(self.startDate)
                let minutes = floor(elapsedTime / 60)
                let seconds = floor(elapsedTime - minutes * 60)
                
                let avgTime = elapsedTime / Double(self.current)
                let eta = Double(self.tasks.count) * avgTime - elapsedTime
                let remainingMinutes = floor(eta / 60)
                let remainingSeconds = floor(eta - remainingMinutes * 60)
                
                DispatchQueue.main.async {
                    self.time.text = String(format: "%02d:%02d", Int(minutes), Int(seconds))
                    self.remainingTime.text = String(format: "-%02d:%02d", Int(remainingMinutes), Int(remainingSeconds))
                }
            }
            MeshNetworkManager.instance.delegate = self
            inProgress = true
            executeNext()
        }
        
    }
    
}

private extension ConfigurationViewController {
    
    func executeNext() {
        current += 1
        
        if !tasks.isEmpty {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.current < self.tasks.count {
                    self.statusView.text = self.tasks[self.current].title
                }
            }
        }
        
        // Are we done?
        if current >= tasks.count || !inProgress {
            handler = nil
            inProgress = false
            
            DispatchQueue.main.async {
                self.statusView.text = "\(self.current) tasks completed (\(self.failed) failed)."
                self.doneButton.isHidden = false
                self.cancelButton.isHidden = true
                self.remainingTime.isHidden = true
            }
            return
        }
        
        // Pop new task and execute.
        let task = tasks[current]
        let message = task.message
        responseOpCode = message.responseOpCode
        
        let manager = MeshNetworkManager.instance
        do {
            handler = try manager.send(message, to: node.primaryUnicastAddress)
        } catch {
            DispatchQueue.main.async {
                self.statusView.text = error.localizedDescription
                self.doneButton.isHidden = false
                self.cancelButton.isHidden = true
                self.remainingTime.isHidden = true
            }
        }
    }
    
    func makeBlue(_ button: UIButton) {
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.almostWhite, for: .highlighted)
        button.backgroundColor = .dynamicColor(light: .nordicLake, dark: .nordicBlue)
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
    }
    
    func makeOrange(_ button: UIButton) {
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.almostWhite, for: .highlighted)
        button.backgroundColor = .nordicFall
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
    }
    
}

extension ConfigurationViewController: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didReceiveMessage message: MeshMessage,
                            sentFrom source: Address,
                            to destination: Address) {
        if current >= 0 && current < tasks.count && message.opCode == responseOpCode {
            if let status = message as? ConfigStatusMessage,
               !status.isSuccess {
                failed += 1
                DispatchQueue.main.async {
                    self.progress.addFail()
                }
            } else {
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
        statusView.text = error.localizedDescription
        doneButton.isHidden = false
        cancelButton.isHidden = true
        remainingTime.isHidden = true
    }
    
}
