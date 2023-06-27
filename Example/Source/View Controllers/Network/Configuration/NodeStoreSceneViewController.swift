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

protocol SceneDelegate {
    /// This method is called when a new Scene has been stored on the Node.
    ///
    /// - parameter scene: The new scene number.
    func sceneAdded(_ scene: SceneNumber)
}

class NodeStoreSceneViewController: ProgressViewController {
    
    // MARK: - Outlets and Actions
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        guard let selectedIndexPath = selectedIndexPath else {
            return
        }
        let selectedScene = selectedIndexPath.section == 0 ?
            newScenes[selectedIndexPath.row] : currentScenes[selectedIndexPath.row]
        storeScene(selectedScene.number)
    }
    
    // MARK: - Properties
    
    var node: Node! {
           didSet {
               if let primaryElement = node.primaryElement {
                   sceneSetupServerModel = primaryElement.model(withSigModelId: .sceneSetupServerModelId)
               }
           }
       }
    var delegate: SceneDelegate?
    
    /// A model that supports Scene Store and Scene Delete messages.
    private var sceneSetupServerModel: Model!
    /// Scenes that are not yet stored on the Node.
    private var newScenes: [Scene]!
    /// Scenes currently present in the Scene Register on the Node.
    private var currentScenes: [Scene]!
    /// Selected Index Path, or `nil`, if nothing is selected.
    private var selectedIndexPath: IndexPath?
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let presentScenesSettings = UIButtonAction(title: "Settings") { [weak self] in
            guard let self = self else { return }
            let tabBarController = self.presentingViewController as? RootTabBarController
            self.dismiss(animated: true) {
                tabBarController?.presentScenesSettings()
            }
        }
        tableView.setEmptyView(title: "No scenes",
                               message: "Go to Settings to create a new scene.",
                               messageImage: #imageLiteral(resourceName: "baseline-scene"),
                               action: presentScenesSettings)
        
        MeshNetworkManager.instance.delegate = self
        
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        currentScenes = node.scenes
        newScenes = meshNetwork.scenes.filter { !currentScenes.contains($0) }
        if newScenes.isEmpty && currentScenes.isEmpty {
            tableView.showEmptyView()
        }
        // Initially, no Scene is checked.
        doneButton.isEnabled = false
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return (newScenes.isEmpty ? 0 : 1) + (currentScenes.isEmpty ? 0 : 1)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 && !newScenes.isEmpty {
            return newScenes.count
        }
        return currentScenes.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 && !newScenes.isEmpty {
            return "New scenes"
        }
        return "Stored"
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            return "Selecting a scene from above will overwrite its previously associated state."
        }
        if newScenes.isEmpty {
            return "Selecting a scene from above will overwrite its previously associated state. "
                  + "Create more scenes in Settings."
        }
        return "Each node may store up to 16 scenes."
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sceneCell", for: indexPath)

        if indexPath.section == 0 && !newScenes.isEmpty {
            cell.textLabel?.text = newScenes[indexPath.row].name
        } else {
            cell.textLabel?.text = currentScenes[indexPath.row].name
        }
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

private extension NodeStoreSceneViewController {
    
    /// Sends Scene Store message to the target Node.
    ///
    /// - parameter sceneNumber: The Scene number to be stored.
    func storeScene(_ sceneNumber: SceneNumber) {
        guard let model = sceneSetupServerModel else {
            return
        }
        start("Storing Scene...") {
            let message = SceneStore(sceneNumber)
            return try MeshNetworkManager.instance.send(message, to: model)
        }
    }
    
}

extension NodeStoreSceneViewController: MeshNetworkDelegate {
    
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
        guard node.primaryUnicastAddress == source else {
            return
        }
        
        // Handle the message based on its type.
        switch message {
            
        case let status as SceneRegisterStatus:
            done {
                if status.status == .success {
                    self.dismiss(animated: true)
                    self.delegate?.sceneAdded(status.currentScene)
                } else {
                    self.presentAlert(title: "Error", message: status.message)
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
        // Ignore messages sent using model publication.
        guard message is SceneStore else {
            return
        }
        done {
            self.presentAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
}
