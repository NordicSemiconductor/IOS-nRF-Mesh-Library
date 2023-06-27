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

class ScenesViewController: UITableViewController, Editable {

    override func viewDidLoad() {
        super.viewDidLoad()
        let generate = UIButtonAction(title: "Generate") {
            self.presentTextAlert(title: "Generate scenes",
                                  message: "Specify number of scenes to generate (max 20):",
                                  placeHolder: "E.g. 3", type: .numberRequired,
                                  cancelHandler: nil) { value in
                guard let network = MeshNetworkManager.instance.meshNetwork,
                      let number = Int(value), number > 0 else {
                    return
                }
                for _ in 0..<min(number, 20) {
                    guard let scene = network.nextAvailableScene() else {
                        break
                    }
                    try? network.add(scene: scene, name: "Scene \(scene)")
                }
                self.tableView.reloadData()
                self.hideEmptyView()
            }
        }
        tableView.setEmptyView(title: "No scenes",
                               message: "Click + to add a new scene.",
                               messageImage: #imageLiteral(resourceName: "baseline-scene"),
                               action: generate)
        
        let hasScenes = MeshNetworkManager.instance.meshNetwork?.scenes.count ?? 0 > 0
        if !hasScenes {
            showEmptyView()
        } else {
            hideEmptyView()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let target = segue.destination as! UINavigationController
        let viewController = target.topViewController! as! EditSceneViewController
        viewController.delegate = self
        
        if let cell = sender as? UITableViewCell {
            let indexPath = tableView.indexPath(for: cell)!
            let network = MeshNetworkManager.instance.meshNetwork!
            viewController.indexPath = indexPath
            viewController.scene = network.scenes[indexPath.sceneIndex]
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        let scenes = MeshNetworkManager.instance.meshNetwork?.scenes ?? []
        return scenes.isEmpty ? 0 : IndexPath.numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let scenes = MeshNetworkManager.instance.meshNetwork?.scenes ?? []
        return scenes.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "User scenes"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sceneCell", for: indexPath)
        let network = MeshNetworkManager.instance.meshNetwork!
        let scene = network.scenes[indexPath.sceneIndex]
        cell.textLabel?.text = scene.name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let network = MeshNetworkManager.instance.meshNetwork!
        let scene = network.scenes[indexPath.sceneIndex]
        
        // It should not be possible to delete a scene that is in use.
        if scene.isUsed {
            return UISwipeActionsConfiguration(actions: [
                UIContextualAction(style: .normal, title: "Scene in use", handler: { _, _, completionHandler in
                    completionHandler(false)
                })
            ])
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteScene(at: indexPath)
        }
    }

}

private extension ScenesViewController {
    
    var sceneExists: Bool {
        let network = MeshNetworkManager.instance.meshNetwork!
        return !network.scenes.isEmpty
    }
    
    func deleteScene(at indexPath: IndexPath) {
        let network = MeshNetworkManager.instance.meshNetwork!
        let scene = network.scenes[indexPath.sceneIndex].number
        _ = try! network.remove(scene: scene)
        
        tableView.beginUpdates()
        tableView.deleteRows(at: [indexPath], with: .top)
        if network.scenes.isEmpty {
            tableView.deleteSections(.scenesSection, with: .fade)
            showEmptyView()
        }
        tableView.endUpdates()
        
        if !MeshNetworkManager.instance.save() {
            self.presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
        }
    }
    
}

extension ScenesViewController: EditSceneDelegate {
    
    func sceneWasAdded() {
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        let count = meshNetwork.scenes.count
        
        tableView.beginUpdates()
        if count == 1 {
            tableView.insertSections(.scenesSection, with: .fade)
            tableView.insertRows(at: [IndexPath(row: 0)], with: .top)
        } else {
            tableView.insertRows(at: [IndexPath(row: count - 1)], with: .top)
        }
        tableView.endUpdates()
        hideEmptyView()
    }
    
    func sceneWasModified(_ indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
}


private extension IndexPath {
    static let scenesSection = 0
    static let numberOfSections = IndexPath.scenesSection + 1
    
    /// Returns the Scene index in mesh network based on the IndexPath.
    var sceneIndex: Int {
        return section + row
    }
    
    init(row: Int) {
        self.init(row: row, section: IndexPath.scenesSection)
    }
}

private extension IndexSet {
    
    static let scenesSection = IndexSet(integer: IndexPath.scenesSection)
    
}
