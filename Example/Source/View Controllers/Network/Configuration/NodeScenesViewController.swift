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
        
        tableView.setEmptyView(title: "No scenes",
                               message: "Pull to refresh, or click + to store a new scene.",
                               messageImage: #imageLiteral(resourceName: "baseline-scene"))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateEmptyView()
        
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
        if segue.identifier == "recall" {
            let cell = sender! as! UITableViewCell
            let indexPath = tableView.indexPath(for: cell)!
            
            let navigationController = segue.destination as! UINavigationController
            let viewController = navigationController.topViewController as! NodeSceneRecallViewController
            let scene = node.scenes[indexPath.sceneIndex]
            viewController.scene = scene
            viewController.delegate = self
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return node.scenes.isEmpty ? 0 : IndexPath.numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return node.scenes.count
    }
    
    override func tableView(_ tableView: UITableView,
                            titleForFooterInSection section: Int) -> String? {
        return "Tap a scene to recall it. Current scene is marked with a checkmark. "
             + "If no scene is checked, no scene is currently presented, or the current "
             + "scene is unknown. Pull to refresh stored scenes."
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
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if !isSceneClientReadyToSetup {
            return UISwipeActionsConfiguration(actions: [
                UIContextualAction(style: .normal, title: "Client not ready", handler: { [weak self] _, _, completionHandler  in
                    guard let self = self else {
                        completionHandler(false)
                        return
                    }
                    completionHandler(self.ensureClientReadyToDelete())
                })
            ])
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView,
                            editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return isSceneClientReadyToSetup ? .delete : .none
    }
    
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let scene = node.scenes[indexPath.sceneIndex]
            deleteScene(scene.number)
        }
    }

}

extension NodeScenesViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        MeshNetworkManager.instance.delegate = self
    }
    
}

// To be able to send messages to Scene Server and Scene Setup Server models
// both of them need to have an Application Key(s) bound. As the returned
// Status messages are processed by local Scene Client model, it also need
// to be bound to the same keys. Otherwise, the response would only be returned
// to the delegate, but would not be processed by the client model, and therefore
// not saved in the mesh network database.
private extension NodeScenesViewController {
    
    /// Whether the Scene Server model has at least one Application Key bound
    /// to it.
    var isSceneServerReady: Bool {
        return !(node.primaryElement?
            .model(withSigModelId: .sceneServerModelId)?
            .boundApplicationKeys.isEmpty ?? true)
    }
    
    /// Whether the Scene Setup Server model has at least one Application Key
    /// bound to it.
    var isSceneSetupServerReady: Bool {
        return !(node.primaryElement?
            .model(withSigModelId: .sceneSetupServerModelId)?
            .boundApplicationKeys.isEmpty ?? true)
    }
    
    /// Whether the local Scene Client model has at least one Application Key
    /// bound to it, that is also bound to Scene Server model on the target Node.
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
        // If they are set, check if Scene Client is also bound to those keys.
        return sceneServerKey == nil || sceneClientKeys.contains(sceneServerKey!)
    }
    
    /// Whether the local Scene Client model has at least one Application Key
    /// bound to it, that is also bound to Scene Setup Server model on the target
    /// Node.
    var isSceneClientReadyToSetup: Bool {
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
        let sceneSetupServerKey = node.primaryElement?
            .model(withSigModelId: .sceneSetupServerModelId)?
            .boundApplicationKeys.first
        // If they are set, check if Scene Client is also bound to those keys.
        return sceneSetupServerKey == nil || sceneClientKeys.contains(sceneSetupServerKey!)
    }
    
    /// Updates the Empty View based on how the models are configured.
    func updateEmptyView() {
        let sceneServerReady = isSceneServerReady
        let sceneSetupServerReady = isSceneSetupServerReady
        let sceneClientReady = isSceneClientReady
        let sceneClientReadyToSetup = isSceneClientReadyToSetup
        if sceneServerReady && sceneClientReady && sceneSetupServerReady && sceneClientReadyToSetup {
            tableView.updateEmptyView(title: "No scenes",
                                      message: "Pull to refresh, or click + to store a new scene.")
            navigationItem.rightBarButtonItem?.isEnabled = true
        } else if sceneServerReady && sceneClientReady {
            // When the Scene Setup Server on the Node has an Application Key bound to it,
            // but the local Scene Client model does not, this action will automatically
            // fix this by binding the same Application Key to the client model.
            // If no key is bound to the server model, automatic fix is not possible,
            // as user may want to select which App Key to use.
            let fixClient = sceneSetupServerReady ?
                UIButtonAction(title: "Fix") { [weak self] in
                    self?.fixClient()
                } : nil
            tableView.updateEmptyView(title: "No scenes",
                                      message: "Pull to refresh stored scenes.\n\n"
                                             + "Before you start storing or deleting scenes,\n"
                                             + "bind an application key to Scene Setup Server \(sceneSetupServerReady ? "✅" : "❌")\n"
                                             + "model on the Node, and Scene Client \(sceneClientReadyToSetup ? "✅" : "❌")\n"
                                             + "model on your local node.",
                                      action: fixClient)
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            let fixClient = sceneServerReady ?
                UIButtonAction(title: "Fix") { [weak self] in
                    self?.fixClient()
                } : nil
            tableView.updateEmptyView(title: "Incomplete setup",
                                      message: "Before you start setting up scenes,\n"
                                             + "bind an application key to Scene Server \(sceneServerReady ? "✅" : "❌")\n"
                                             + "and Scene Setup Server \(sceneSetupServerReady ? "✅" : "❌") models on the Node,\n"
                                             + "and Scene Client \(sceneClientReady && sceneClientReadyToSetup ? "✅" : "❌") model on your local node.",
                                      action: fixClient)
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
}

extension NodeScenesViewController: SceneRecallDelegate {
    
    func recallScene(_ scene: SceneNumber, transitionTime: TransitionTime?, delay: UInt8?) {
        guard ensureClientReady() else {
            return
        }
        guard let sceneServerModel = sceneServerModel else {
            return
        }
        start("Recalling Scene...") {
            if let transitionTime = transitionTime, let delay = delay {
                let message = SceneRecall(scene, transitionTime: transitionTime, delay: delay)
                return try MeshNetworkManager.instance.send(message, to: sceneServerModel)
            } else {
                let message = SceneRecall(scene)
                return try MeshNetworkManager.instance.send(message, to: sceneServerModel)
            }
        }
    }
    
}

private extension NodeScenesViewController {
    
    @objc func getScenes() {
        guard ensureClientReady() else {
            return
        }
        guard let sceneServerModel = sceneServerModel else {
            return
        }
        // Note: Scene Register Get will return no current Scene (invalid scene)
        //       when transition is in progress, so Scene Get will be sent afterwards.
        start("Reading Scene Register...") {
            let message = SceneRegisterGet()
            return try MeshNetworkManager.instance.send(message, to: sceneServerModel)
        }
    }
    
    func getCurrentScene() {
        guard ensureClientReady() else {
            return
        }
        guard let sceneServerModel = sceneServerModel else {
            return
        }
        start("Reading Current Scene...") {
            let message = SceneGet()
            return try MeshNetworkManager.instance.send(message, to: sceneServerModel)
        }
    }
    
    func deleteScene(_ scene: SceneNumber) {
        guard let sceneSetupServerModel = sceneSetupServerModel else {
            return
        }
        start("Deleting Scene...") {
            let message = SceneDelete(scene)
            return try MeshNetworkManager.instance.send(message, to: sceneSetupServerModel)
        }
    }
    
    func ensureClientReady() -> Bool {
        // Refreshing will only work if there is at least one Application Key bound
        // to both Scene Server on the target Node, and Scene Client model on the
        // local Node.
        guard isSceneServerReady else {
            presentAlert(title: "Scene Server not ready",
                         message: "Scene Server model on the node has no Application Keys bound "
                                + "to it. Configure the model before refreshing scenes.")
            return false
        }
        guard isSceneClientReady else {
            let action = UIAlertAction(title: "Fix", style: .default) { [weak self] action in
                self?.fixClient()
            }
            presentAlert(title: "Client not ready",
                         message: "Scene Client model on local node is not bound to any of the "
                                + "keys bound to Scene Server model on the node.",
                         option: action)
            return false
        }
        return true
    }
    
    func ensureClientReadyToDelete() -> Bool {
        // Deleting will only work if there is at least one Application Key bound
        // to both Scene Setup Server on the target Node, and Scene Client model on the
        // local Node.
        guard isSceneSetupServerReady else {
            presentAlert(title: "Scene Setup Server not ready",
                         message: "Scene Setup Server model on the node has no Application Keys "
                                + "bound to it. Configure the model before deleting scenes.")
            return false
        }
        guard isSceneClientReadyToSetup else {
            let action = UIAlertAction(title: "Fix", style: .default) { [weak self] action in
                self?.fixClient()
            }
            presentAlert(title: "Client not ready",
                         message: "Scene Client model on local node is not bound to any of the "
                                + "keys bound to Scene Setup Server model on the node.",
                         option: action)
            return false
        }
        return true
    }
    
    /// This method tried to bind the Application Keys bound to Scene Server and
    /// Scene Setup Server on the target Node to the local Scene Client model.
    func fixClient() {
        let sceneServerApplicationKey = node.primaryElement?
            .model(withSigModelId: .sceneServerModelId)?
            .boundApplicationKeys.first
        let sceneSetupServerApplicationKey = node.primaryElement?
            .model(withSigModelId: .sceneSetupServerModelId)?
            .boundApplicationKeys.first
        guard sceneServerApplicationKey != nil ||
              sceneSetupServerApplicationKey != nil else {
            return
        }
        guard let network = MeshNetworkManager.instance.meshNetwork,
              let localNode = network.localProvisioner?.node,
              let primaryElement = localNode.primaryElement,
              let sceneClient = primaryElement.model(withSigModelId: .sceneClientModelId) else {
            return
        }
        start("Binding Application Key...") {
            var handler: MessageHandle?
            if let key = sceneServerApplicationKey {
                let message = ConfigModelAppBind(applicationKey: key,
                                                 to: sceneClient)!
                handler = try MeshNetworkManager.instance.sendToLocalNode(message)
            }
            if let key = sceneSetupServerApplicationKey {
                let message = ConfigModelAppBind(applicationKey: key,
                                                 to: sceneClient)!
                handler = try MeshNetworkManager.instance.sendToLocalNode(message)
            }
            return handler
        }
    }
    
    @discardableResult func setCurrentScene(_ currentScene: SceneNumber) -> [IndexPath] {
        var rows: [IndexPath] = []
        if let currentSceneIndexPath = currentSceneIndexPath {
            rows.append(currentSceneIndexPath)
        }
        if currentScene.isValidSceneNumber,
           let index = node.scenes.firstIndex(where: { $0.number == currentScene }) {
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
                            sentFrom source: Address, to destination: MeshAddress) {
        // Has the Node been reset remotely.
        guard !(message is ConfigNodeReset) else {
            (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
            done {
                self.navigationController?.popToRootViewController(animated: true)
            }
            return
        }
            
        if let status = message as? ConfigModelAppStatus {
            done {
                if status.isSuccess {
                    self.updateEmptyView()
                    self.tableView.reloadData()
                } else {
                    self.presentAlert(title: "Error", message: "\(status.status)")
                }
            }
        }
        
        // Is the message targeting the current Node?
        guard node.primaryUnicastAddress == source else {
            return
        }
        
        // Handle the message based on its type.
        switch message {

        // Response to Scene Recall and Scene Get.
        case let status as SceneStatus:
            done {
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
                tableView.reloadData()
                presentAlert(title: "Error", message: "\(status.status)")
            }
            refreshControl?.endRefreshing()
            
        default:
            break
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            failedToSendMessage message: MeshMessage,
                            from localElement: Element, to destination: MeshAddress,
                            error: Error) {
        // Ignore messages sent using model publication.
        guard message is ConfigMessage ||
              message is SceneRecall ||
              message is SceneGet ||
              message is SceneRegisterGet ||
              message is SceneDelete else {
            return
        }
        done {
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
