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
import nRFMeshProvision

class SceneSetupServerDelegate: ModelDelegate {
    /// Maximum size of the Scene Register.
    private static let maxScenes = 16
    
    /// The Scene Server model, which this model extends.
    let server: SceneServerDelegate
    
    let messageTypes: [UInt32 : MeshMessage.Type]
    let isSubscriptionSupported: Bool = true
    let publicationMessageComposer: MessageComposer? = nil
    
    init(server delegate: SceneServerDelegate) {
        let types: [StaticMeshMessage.Type] = [
            SceneStore.self,
            SceneStoreUnacknowledged.self,
            SceneDelete.self,
            SceneDeleteUnacknowledged.self
        ]
        messageTypes = types.toMap()
        server = delegate
    }
    
    // MARK: - Message handlers
    
    func model(_ model: Model, didReceiveAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) throws -> MeshResponse {
        switch request {
        case let request as SceneStore:
            // Little validation.
            guard request.scene.isValidSceneNumber else {
                throw ModelError.invalidMessage
            }
            
            // Scene Register may contain up to 16 stored Scenes.
            // Overwriting is allowed.
            guard storedScenes.count < Self.maxScenes ||
                  storedScenes.contains(request.scene) else {
                return SceneRegisterStatus(report: currentScene,
                                           and: storedScenes,
                                           with: .sceneRegisterFull)
            }
            
            setCurrentScene(request.scene)
            
            // Store the scene on all Models that support Scenes.
            MeshNetworkManager.instance.localElements
                .flatMap { $0.models }
                .compactMap { $0.delegate as? StoredWithSceneModelDelegate }
                .forEach { $0.store(with: request.scene) }
            
        case let request as SceneDelete:
            // Little validation.
            guard request.scene.isValidSceneNumber else {
                throw ModelError.invalidMessage
            }
            
            // If no such Scene was found, return an error.
            guard let index = storedScenes.firstIndex(of: request.scene) else {
                return SceneRegisterStatus(report: currentScene,
                                           and: storedScenes,
                                           with: .sceneNotFound)
            }
            
            removeScene(at: index)
            
        default:
            fatalError("Not possible")
        }
        
        return SceneRegisterStatus(report: currentScene, and: storedScenes)
    }
    
    func model(_ model: Model, didReceiveUnacknowledgedMessage message: UnacknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) {
        switch message {
        case let request as SceneStoreUnacknowledged:
            // Little validation.
            guard request.scene.isValidSceneNumber else {
                return
            }
            
            // Scene Register may contain up to 16 stored Scenes.
            // Overwriting is allowed.
            guard storedScenes.count < Self.maxScenes ||
                  storedScenes.contains(request.scene) else {
                return
            }
            setCurrentScene(request.scene)
            
            // Store the scene on all Models that support Scenes.
            MeshNetworkManager.instance.localElements
                .flatMap { $0.models }
                .compactMap { $0.delegate as? StoredWithSceneModelDelegate }
                .forEach { $0.store(with: request.scene) }
            
        case let request as SceneDeleteUnacknowledged:
            // Little validation.
            guard request.scene.isValidSceneNumber else {
                return
            }
            
            // If no such Scene was found, ignore
            guard let index = storedScenes.firstIndex(of: request.scene) else {
                return
            }
            removeScene(at: index)
            
        default:
            // Not possible.
            break
        }
    }
    
    func model(_ model: Model, didReceiveResponse response: MeshResponse,
               toAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address) {
        // Not possible.
    }
    
}
