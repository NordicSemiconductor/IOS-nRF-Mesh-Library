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
    case sendNetworkKey(_ networkKey: NetworkKey)
    case sendApplicationKey(_ applicationKey: ApplicationKey)
    case bind(_ applicationKey: ApplicationKey, to: Model)
    
    var title: String {
        switch self {
        case .sendNetworkKey(let key):
            return "Send \(key.name)"
        case .sendApplicationKey(let key):
            return "Send \(key.name)"
        case .bind(let key, to: let model):
            return "Bind \(key.name) to \(model)"
        }
    }
    
    var message: AcknowledgedConfigMessage {
        switch self {
        case .sendNetworkKey(let key):
            return ConfigNetKeyAdd(networkKey: key)
        case .sendApplicationKey(let key):
            return ConfigAppKeyAdd(applicationKey: key)
        case .bind(let key, to: let model):
            return ConfigModelAppBind(applicationKey: key, to: model)!
        }
    }
}

class ConfigurationViewController: UITableViewController, UIAdaptivePresentationControllerDelegate {
    
    // MARK: - Public properties
    
    var node: Node!
    
    func bind(applicationKeys: [ApplicationKey], to models: [Model]) {
        guard let node = models.first?.parentElement?.parentNode else {
            return
        }
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
    
    private var tasks: [Task] = []
    private var inProgress: Bool = false
    private var current: Int = -1
    private var responseOpCode: UInt32?
    
    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make the dialog modal (non-dismissable).
        navigationController?.presentationController?.delegate = self
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // Allow dismiss only when all tasks are complete.
        return !inProgress
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if tasks.isEmpty {
            presentAlert(title: "Completed", message: "The node is already configured.") { _ in
                self.navigationController?.dismiss(animated: true)
            }
        }
        
        MeshNetworkManager.instance.delegate = self
        executeNext()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let task = tasks[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "task", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row + 1). \(task.title)"
        
        if indexPath.row < current {
            cell.accessoryType = .checkmark
            cell.accessoryView = nil
        } else if indexPath.row > current || !inProgress {
            cell.accessoryType = .none
            cell.accessoryView = nil
        } else {
            let i = UIActivityIndicatorView(style: .gray)
            i.startAnimating()
            cell.accessoryView = i
        }
        
        return cell
    }

}

private extension ConfigurationViewController {
    
    func executeNext() {
        inProgress = true
        current += 1
        
        // Refresh table.
        DispatchQueue.main.async {
            // Refresh previous and new rows.
            var rows: [IndexPath] = []
            if self.current > 0 {
                rows.append(IndexPath(row: self.current - 1, section: 0))
            }
            if self.current < self.tasks.count {
                rows.append(IndexPath(row: self.current, section: 0))
            }
            self.tableView.reloadRows(at: rows, with: .automatic)
        }
        
        // Are we done?
        if current >= tasks.count {
            inProgress = false
            
            presentAlert(title: "Completed", message: "\(tasks.count) tasks completed successfully.") { _ in
                self.navigationController?.dismiss(animated: true)
            }
            return
        }
        
        // Pop new task and execute.
        let task = tasks[current]
        let message = task.message
        responseOpCode = message.responseOpCode
        
        let manager = MeshNetworkManager.instance
        do {
            try manager.send(message, to: node.primaryUnicastAddress)
        } catch {
            presentAlert(title: "Error", message: error.localizedDescription) { _ in
                self.navigationController?.dismiss(animated: true)
            }
        }
    }
    
}

extension ConfigurationViewController: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didReceiveMessage message: MeshMessage,
                            sentFrom source: Address,
                            to destination: Address) {
        if current >= 0 && current < tasks.count && message.opCode == responseOpCode {
            executeNext()
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            failedToSendMessage message: MeshMessage,
                            from localElement: Element,
                            to destination: Address,
                            error: Error) {
        inProgress = false
        tableView.reloadRows(at: [IndexPath(row: current, section: 0)], with: .automatic)
        presentAlert(title: "Error", message: error.localizedDescription) { _ in
            self.navigationController?.dismiss(animated: true)
        }
    }
    
}
