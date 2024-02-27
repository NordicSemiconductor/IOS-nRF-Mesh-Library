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

import Foundation

internal class SceneClientHandler: ModelDelegate {
    weak var meshNetwork: MeshNetwork!
    
    let messageTypes: [UInt32 : MeshMessage.Type]
    let isSubscriptionSupported: Bool = true
    // TODO: Implement Scene Client publications.
    let publicationMessageComposer: MessageComposer? = nil
    
    init(_ meshNetwork: MeshNetwork) {
        let types: [StaticMeshMessage.Type] = [
            // A Scene Server shall send the Scene Status message as a response to
            // a Scene Get and Scene Recall message, or as an unsolicited message.
            SceneStatus.self,
            // A Scene Server shall send the Scene Register Status message either
            // as a response to a Scene Store message or a Scene Register Get message,
            // or as an unsolicited message.
            SceneRegisterStatus.self
        ]
        self.meshNetwork = meshNetwork
        self.messageTypes = types.toMap()
    }
    
    func model(_ model: Model, didReceiveAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) -> MeshResponse {
        switch request {
            // No acknowledged message supported by this Model.
        default:
            fatalError("Message not supported: \(request)")
        }
    }
    
    func model(_ model: Model, didReceiveUnacknowledgedMessage message: UnacknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) {
        handle(message, sentFrom: source)
    }
    
    func model(_ model: Model, didReceiveResponse response: MeshResponse,
               toAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address) {
        handle(response, sentFrom: source)
    }
}

private extension SceneClientHandler {
    
    func handle(_ message: MeshMessage, sentFrom source: Address) {
        switch message {
            
        // Response to Scene Get and Scene Recall.
        case let status as SceneStatus:
            if status.scene.isValidSceneNumber {
                // Ensure the current scene is updated with the Node address.
                if let sceneObject = meshNetwork.scenes[status.scene] {
                    sceneObject.add(address: source)
                } else {
                    let sceneObject = Scene(status.scene,
                                                  name: NSLocalizedString("New Scene", comment: ""))
                    sceneObject.add(address: source)
                    meshNetwork.add(scene: sceneObject)
                }
                
                // Ensure the target scene, if exists, is updated with the Node address.
                if let targetScene = status.targetScene,
                   targetScene.isValidSceneNumber {
                    if let sceneObject = meshNetwork.scenes[targetScene] {
                        sceneObject.add(address: source)
                    } else {
                        let sceneObject = Scene(targetScene,
                                                      name: NSLocalizedString("New Scene", comment: ""))
                        sceneObject.add(address: source)
                        meshNetwork.add(scene: sceneObject)
                    }
                }
            }
            
        // Response to Scene Register Get, Scene Store and Scene Delete.
        case let status as SceneRegisterStatus:
            /// Scenes confirmed to be in the Scene Register on the Node.
            let confirmedScenes = status.scenes.filter { $0.isValidSceneNumber }
            // Add the Node to all confirmed scenes.
            for scene in confirmedScenes {
                if let sceneObject = meshNetwork.scenes[scene] {
                    sceneObject.add(address: source)
                } else {
                    let sceneObject = Scene(scene,
                                                  name: NSLocalizedString("New Scene", comment: ""))
                    sceneObject.add(address: source)
                    meshNetwork.add(scene: sceneObject)
                }
            }
            // Remove this Scene from scenes, that it is confirmed not to have
            // stored (that is all other that confirmed).
            meshNetwork.scenes
                .filter { !confirmedScenes.contains($0.number) }
                .forEach { $0.remove(address: source) }
            
        default:
            break
        }
    }
    
}
