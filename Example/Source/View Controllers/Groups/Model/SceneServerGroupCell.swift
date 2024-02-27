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
import NordicMesh

class SceneServerGroupCell: ModelGroupCell {
    
    // MARK: - Outlets and Actions
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var recallButton: UIButton!
    @IBAction func recallTapped(_ sender: UIButton) {
        showSceneSelector()
    }
    
    // MARK: - Implementation
    
    override func reload() {
        // On iOS 12.x tinted icons are initially black.
        // Forcing adjustment mode fixes the bug.
        icon.tintAdjustmentMode = .normal
        
        let numberOfDevices = models.count
        if numberOfDevices == 1 {
            title.text = "1 device"
        } else {
            title.text = "\(numberOfDevices) devices"
        }
        
        let localProvisioner = MeshNetworkManager.instance.meshNetwork?.localProvisioner
        let isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
        
        recallButton.isEnabled = isEnabled
    }
}

private extension SceneServerGroupCell {
    
    /// Displays list of Scenes present in a Scene Register of at least one Node
    /// which Scene Server model is subscribed to this Group and bound to the
    /// Application Key.
    func showSceneSelector() {
        let scenes = group.scenes(onModelsBoundTo: applicationKey)
        guard !scenes.isEmpty else {
            parentViewController?.presentAlert(title: "No scenes",
                                               message: "No scene found in Scene Registers on nodes "
                                                      + "subscribed to this group with Scene Server "
                                                      + "models bound to key \(applicationKey!.name).")
            return
        }
        let alert = UIAlertController(title: "Select scene", message: nil, preferredStyle: .actionSheet)
        scenes.forEach { scene in
            alert.addAction(UIAlertAction(title: scene.name, style: .default) { [weak self] _ in
                self?.sendSceneRecall(scene.number)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        parentViewController?.present(alert, animated: true)
    }
    
    /// Sends Scene Recall Unacknowledged message.
    ///
    /// - parameter scene: The Scene number to recall.
    func sendSceneRecall(_ scene: SceneNumber) {
        let label = "Recalling scene..."
        delegate?.send(SceneRecallUnacknowledged(scene),
                       description: label, using: applicationKey)
    }
    
}
