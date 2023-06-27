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

protocol BindAppKeyDelegate {
    /// This method is called when a new Application Key has been bound to the Model.
    func keyBound()
    /// This method will present Node's Application Keys configuration screen.
    func presentNodeApplicationKeys()
}

class ModelBindAppKeyViewController: ProgressViewController {
    
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
        let presentNodeApplicationKeys = UIButtonAction(title: "Add key") { [weak self] in
            self?.dismiss(animated: true) { [weak self] in
                self?.delegate?.presentNodeApplicationKeys()
            }
        }
        tableView.setEmptyView(title: "No keys available",
                               message: "Add a new key to the node first.",
                               messageImage: #imageLiteral(resourceName: "baseline-key"),
                               action: presentNodeApplicationKeys)
        
        MeshNetworkManager.instance.delegate = self
        
        keys = model.parentElement?.parentNode?.applicationKeys(availableForModel: model)
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
        guard let selectedIndexPath = selectedIndexPath,
              let model = model,
              let node = model.parentElement?.parentNode else {
            return
        }
        let selectedAppKey = keys[selectedIndexPath.row]
        start("Binding Application Key...") {
            let message = ConfigModelAppBind(applicationKey: selectedAppKey, to: model)!
            return try MeshNetworkManager.instance.send(message, to: node)
        }
    }
    
}

extension ModelBindAppKeyViewController: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didReceiveMessage message: MeshMessage,
                            sentFrom source: Address, to destination: MeshAddress) {
        // Has the Node been reset remotely.
        guard !(message is ConfigNodeReset) else {
            (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
            done {
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
        // Is the message targeting the current Node?
        guard model.parentElement?.parentNode?.primaryUnicastAddress == source else {
            return
        }
        
        // Handle the message based on its type.
        switch message {
            
        case let status as ConfigModelAppStatus:
            done {
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
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            failedToSendMessage message: MeshMessage,
                            from localElement: Element, to destination: MeshAddress,
                            error: Error) {
        // Ignore messages sent from model publication.
        guard message is ConfigMessage else {
            return
        }
        done {
            self.presentAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
}
