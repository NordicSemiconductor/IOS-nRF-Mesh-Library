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

class NodeScenesViewController: ProgressViewController, Editable {
    
    // MARK: - Properties
    
    var node: Node! {
        didSet {
            if let primaryElement = node.primaryElement {
                sceneServerModel = primaryElement.model(withSigModelId: .sceneServerModelId)
                sceneSetupServerModel = primaryElement.model(withSigModelId: .sceneSetupServerModelId)
            }
        }
    }
    
    // MARK: - Private properties
    
    /// A model that supports Scene Get, Scene Register Get and Scene Recall messages.
    private var sceneServerModel: Model!
    /// A model that supports Scene Store and Scene Delete messages.
    private var sceneSetupServerModel: Model!
    /// The current Scene IndexPath. This is not stored in the DB and has to be obtained
    /// from the device. If set to `nil`, the value is unknown or the Node has no current
    /// scene set.
    private var currentSceneIndexPath: IndexPath?
    
    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sceneServerReady = isSceneServerReady
        let sceneSetupServerReady = isSceneSetupServerReady
        let sceneClientReady = isSceneClientReady
        if sceneServerReady && sceneSetupServerReady && sceneClientReady {
            tableView.setEmptyView(title: "No scenes",
                                   message: "Pull to refresh, or click + to store a new scene.",
                                   messageImage: #imageLiteral(resourceName: "baseline-scene"))
        } else {
            tableView.setEmptyView(title: "Incomplete setup",
                                   message: "Before you start setting up scenes,\n"
                                    + "bind an application key to Scene Server \(sceneServerReady ? "✅" : "❌")\n"
                                          + "and Scene Setup Server \(sceneSetupServerReady ? "✅" : "❌") models on the Node\n"
                                          + "and Scene Client \(sceneClientReady ? "✅" : "❌") model on your local node.",
                                   messageImage: #imageLiteral(resourceName: "baseline-scene"))
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard isSetupReady else {
            showEmptyView()
            refreshControl = nil
            return
        }
        
        if node.scenes.isEmpty {
            showEmptyView()
        } else {
            hideEmptyView()
        }
        
        // Check if the local Provisioner has configuration capabilities.
        let localProvisioner = MeshNetworkManager.instance.meshNetwork?.localProvisioner
        guard localProvisioner?.hasConfigurationCapabilities ?? false else {
            // The Provisioner cannot sent or receive messages.
            refreshControl = nil
            return
        }
        
        if refreshControl == nil {
            refreshControl = UIRefreshControl()
            refreshControl!.tintColor = UIColor.white
            refreshControl!.addTarget(self, action: #selector(getScenes), for: .valueChanged)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        MeshNetworkManager.instance.delegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "add" {
            let navigationController = segue.destination as! UINavigationController
            navigationController.presentationController?.delegate = self
            let viewController = navigationController.topViewController as! NodeStoreSceneViewController
            viewController.node = node
            viewController.delegate = self
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return !isSetupReady || node.scenes.isEmpty ? 0 : IndexPath.numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return node.scenes.count
    }
    
    override func tableView(_ tableView: UITableView,
                            titleForFooterInSection section: Int) -> String? {
        return "Tap a scene to recall it. Current scene is marked with a checkmark. "
             + "If no scene is checked, no scene is currently presented, or the current "
             + "scene is unknown. Pull to read Scene Register."
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sceneCell", for: indexPath)
        
        let scene = node.scenes[indexPath.sceneIndex]
        cell.textLabel?.text = scene.name
        cell.accessoryType = indexPath == currentSceneIndexPath ? .checkmark : .none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let scene = node.scenes[indexPath.sceneIndex]
        recallScene(scene.number)
    }
    
    override func tableView(_ tableView: UITableView,
                            editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        // This is required to allow swipe to delete action.
        return nil
    }
    
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        let scene = node.scenes[indexPath.sceneIndex]
        deleteScene(scene.number)
    }

}

extension NodeScenesViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        MeshNetworkManager.instance.delegate = self
    }
    
}

private extension NodeScenesViewController {
    
    /// Returns whether Scene models are set up correctly.
    ///
    /// To be able to send messages to Scene Server and Scene Setup Server models
    /// both of them need to have an Application Key(s) bound. As the returned
    /// Status messages are processed by local Scene Client model, it also need
    /// to be bound to the same keys. Otherwise, the response would only be returned
    /// to the delegate, but would not be processed by the client model, and therefore
    /// not saved in the mesh network database.
    var isSetupReady: Bool {
        return isSceneClientReady && isSceneServerReady && isSceneSetupServerReady
    }
    
    var isSceneServerReady: Bool {
        return !(node.primaryElement?
            .model(withSigModelId: .sceneServerModelId)?
            .boundApplicationKeys.isEmpty ?? true)
    }
    
    var isSceneSetupServerReady: Bool {
        return !(node.primaryElement?
            .model(withSigModelId: .sceneSetupServerModelId)?
            .boundApplicationKeys.isEmpty ?? true)
    }
    
    var isSceneClientReady: Bool {
        guard let network = MeshNetworkManager.instance.meshNetwork,
              let localNode = network.localProvisioner?.node,
              let primaryElement = localNode.primaryElement,
              let sceneClientKeys = primaryElement
                        .model(withSigModelId: .sceneClientModelId)?
                        .boundApplicationKeys,
                 !sceneClientKeys.isEmpty else {
            return false
        }
        // Messages will be sent using the first bound Application Key.
        let sceneServerKey = node.primaryElement?
            .model(withSigModelId: .sceneServerModelId)?
            .boundApplicationKeys.first
        let sceneSetupServerKey = node.primaryElement?
            .model(withSigModelId: .sceneSetupServerModelId)?
            .boundApplicationKeys.first
        // If they are set, check if Scene Client is also bound to those keys.
        return (sceneServerKey == nil || sceneClientKeys.contains(sceneServerKey!)) &&
               (sceneSetupServerKey == nil || sceneClientKeys.contains(sceneSetupServerKey!))
    }
    
    @objc func getScenes() {
        // Scene Register Get will return no current Scene it transition is in progress.
        start("Reading Scene Register...") {
            let message = SceneRegisterGet()
            return try MeshNetworkManager.instance.send(message, to: self.sceneServerModel)
        }
    }
    
    func getCurrentScene() {
        start("Reading Current Scene...") {
            let message = SceneGet()
            return try MeshNetworkManager.instance.send(message, to: self.sceneServerModel)
        }
    }
    
    func recallScene(_ scene: SceneNumber) {
        start("Recalling Scene...") {
            let transitionTime = TransitionTime(steps: 2, stepResolution: .seconds)
            let message = SceneRecall(scene, transitionTime: transitionTime, delay: 0)
            return try MeshNetworkManager.instance.send(message, to: self.sceneServerModel)
        }
    }
    
    func deleteScene(_ scene: SceneNumber) {
        start("Deleting Scene...") {
            let message = SceneDelete(scene)
            return try MeshNetworkManager.instance.send(message, to: self.sceneSetupServerModel)
        }
    }
    
    @discardableResult func setCurrentScene(_ currentScene: SceneNumber) -> [IndexPath] {
        var rows: [IndexPath] = []
        if let currentSceneIndexPath = currentSceneIndexPath {
            rows.append(currentSceneIndexPath)
        }
        if currentScene.isValidSceneNumber {
            let index = node.scenes.firstIndex { $0.number == currentScene }!
            currentSceneIndexPath = IndexPath(row: index, section: 0)
            rows.append(currentSceneIndexPath!)
        } else {
            currentSceneIndexPath = nil
        }
        return rows
    }
    
    var isRefreshing: Bool {
        return refreshControl?.isRefreshing ?? false
    }
    
}

extension NodeScenesViewController: MeshNetworkDelegate {
    
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
        // Is the message targeting the current Node?
        guard node.unicastAddress == source else {
            return
        }
        
        // Handle the message based on its type.
        switch message {

        // Response to Scene Recall and Scene Get.
        case let status as SceneStatus:
            done() {
                if status.isSuccess {
                    let rows = self.setCurrentScene(status.targetScene ?? status.scene)
                    self.tableView.reloadRows(at: rows, with: .automatic)
                } else {
                    self.presentAlert(title: "Error", message: "\(status.status)")
                }
                self.refreshControl?.endRefreshing()
            }
        
        // Response to Scene Delete.
        case let status as SceneRegisterStatus:
            if !status.isSuccess || status.isEmpty || !isRefreshing {
                done()
            }
            
            if status.isSuccess {
                setCurrentScene(status.currentScene)
                if node.scenes.isEmpty {
                    showEmptyView()
                } else {
                    hideEmptyView()
                }
                tableView.reloadData()

                if isRefreshing && !status.isEmpty {
                    getCurrentScene()
                    return
                }
            } else {
                presentAlert(title: "Error", message: "\(status.status)")
            }
            self.refreshControl?.endRefreshing()
            
        default:
            break
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

extension NodeScenesViewController: SceneDelegate {
    
    func sceneAdded(_ scene: SceneNumber) {
        setCurrentScene(scene)
        tableView.reloadData()
        
        if !node.scenes.isEmpty {
            hideEmptyView()
        }
    }
    
}

private extension IndexPath {
    static let scenesSection = 0
    static let numberOfSections = IndexPath.scenesSection + 1
    
    /// Returns the Application Key index in mesh network based on the
    /// IndexPath.
    var sceneIndex: Int {
        return section + row
    }
    
}
