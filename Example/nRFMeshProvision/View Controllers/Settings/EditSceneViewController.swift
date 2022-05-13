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

protocol EditSceneDelegate {
    /// Notifies the delegate that the Scene was added to the mesh network.
    func sceneWasAdded()
    /// Notifies the delegate that the given Key was modified.
    ///
    /// - parameter indexPath: The IndexPath that has been modified.
    func sceneWasModified(_ indexPath: IndexPath)
}

class EditSceneViewController: UITableViewController {
    
    // MARK: - Actions
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        saveScene()
    }
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    @IBOutlet weak var nameCell: UITableViewCell!
    @IBOutlet weak var sceneNumberCell: UITableViewCell!
    
    // MARK: - Public members
    
    /// The IndexPath that is modified, or `nil` if a new Scene is being added.
    var indexPath: IndexPath?
    /// The Key to be modified. This is `nil` when a new key is being added.
    var scene: Scene?
    /// The delegate will be informed when the Done button is clicked.
    var delegate: EditSceneDelegate?
    
    // MARK: - Private members
    
    var newScene: SceneNumber!
    
    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let action = isNewScene ? "Add" : "Edit"
        title = "\(action) Scene"
        
        if let scene = scene {
            nameCell.detailTextLabel?.text = scene.name
            newScene = scene.number
            sceneNumberCell.detailTextLabel?.text = scene.number.asString()
            sceneNumberCell.accessoryType = .none
            sceneNumberCell.selectionStyle = .none
        } else {
            if let network = MeshNetworkManager.instance.meshNetwork,
               let provisioner = network.localProvisioner,
               let scene = network.nextAvailableScene(for: provisioner) {
                nameCell.detailTextLabel?.text = defaultName
                newScene = scene
                sceneNumberCell.detailTextLabel?.text = scene.asString()
            } else {
                nameCell.detailTextLabel?.text = "N/A"
                nameCell.accessoryType = .none
                nameCell.selectionStyle = .none
                sceneNumberCell.detailTextLabel?.text = "Unavailable"
            }
            sceneNumberCell.accessoryType = .disclosureIndicator
            sceneNumberCell.selectionStyle = .default
        }
        doneButton.isEnabled = isSceneValid
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard isSceneValid else {
            if indexPath.isScene {
                presentAlert(title: "Info", message: "All scene numbers in provisioner's ranges are already used. "
                                                   + "Add new scene range in Settings -> Provisioners -> "
                                                   + "This provisioner -> Scenes, or delete an unused scene "
                                                   + "from current ranges.")
            }
            return
        }
        
        if indexPath.isName {
            presentNameDialog()
        }
        if indexPath.isScene && isNewScene {
            presentSceneDialog()
        }
    }

}

private extension EditSceneViewController {
    
    var isNewScene: Bool {
        return scene == nil
    }
    
    var isSceneValid: Bool {
        return newScene != nil
    }
    
    var defaultName: String {
        guard let network = MeshNetworkManager.instance.meshNetwork,
              let provisioner = network.localProvisioner,
              let nextScene = network.nextAvailableScene(for: provisioner) else {
            return ""
        }
        return "Scene \(nextScene)"
    }
    
    func presentSceneDialog() {
        let title = "New Scene Number"
        let message = "Enter the scene number as 4-character hexadecimal string.\nValid range: 0x0001 - 0xFFFF."
        presentTextAlert(title: title, message: message,
                         text: newScene?.hex, placeHolder: "Scene number",
                         type: .sceneRequired, cancelHandler: nil) { hex in
                            self.newScene = SceneNumber(hex, radix: 16)!
                            self.sceneNumberCell.detailTextLabel?.text = self.newScene.asString()
        }
    }
    
    func presentNameDialog() {
        let name = nameCell.detailTextLabel?.text
        presentTextAlert(title: "Edit Scene Name", message: nil, text: name,
                         placeHolder: "E.g. Sunrise",
                         type: .nameRequired, cancelHandler: nil) { name in
                            self.nameCell.detailTextLabel?.text = name
        }
    }
    
    func saveScene() {
        let network = MeshNetworkManager.instance.meshNetwork!
        
        guard let name = nameCell.detailTextLabel?.text,
              let newScene = newScene else {
            return
        }
        
        if let scene = scene {
            scene.name = name
        } else {
            // Check if no such scene already exist.
            if let existingScene = network.scenes[newScene] {
                presentAlert(title: "Error",
                             message: "Scene with given number already exists: \(existingScene.name)")
            }
            // Check if the scene is in the local Provisioner's range.
            guard let provisioner = network.localProvisioner,
                      provisioner.hasAllocated(sceneNumber: newScene) else {
                presentAlert(title: "Error",
                             message: "Scene is outside of this provisioner scene ranges.")
                return
            }
            try? network.add(scene: newScene, name: name)
        }
            
        if MeshNetworkManager.instance.save() {
            dismiss(animated: true)
            
            // Finally, notify the parent view controller.
            if let indexPath = indexPath {
                delegate?.sceneWasModified(indexPath)
            } else {
                delegate?.sceneWasAdded()
            }
        } else {
            presentAlert(title: "Error", message: "Mesh configuration could not be saved.")
        }
    }
    
}

private extension IndexPath {
    static let nameSection = 0
    static let sceneSection  = 1
    
    /// Returns whether the IndexPath points to the key name.
    var isName: Bool {
        return section == IndexPath.nameSection && row == 0
    }
    
    /// Returns whether the IndexPath point to the Scene number.
    var isScene: Bool {
        return section == IndexPath.sceneSection && row == 0
    }
}
