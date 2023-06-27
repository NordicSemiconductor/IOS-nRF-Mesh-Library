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

class SceneServerDelegate: SceneServerModelDelegate {
    
    /// The Generic Default Transition Time Server model, which this model depends on.
    let defaultTransitionTimeServer: GenericDefaultTransitionTimeServerDelegate
    
    let messageTypes: [UInt32 : MeshMessage.Type]    
    let isSubscriptionSupported: Bool = true
    
    var publicationMessageComposer: MessageComposer? {
        func compose() -> MeshMessage {
            if let (targetScene, complete) = self.targetScene {
                let remainingTime = TransitionTime(complete.timeIntervalSinceNow)
                return SceneStatus(report: targetScene, remainingTime: remainingTime)
            } else {
                return SceneStatus(report: self.currentScene)
            }
        }
        let status = compose()
        return {
            return status
        }
    }
    
    /// Stored scenes.
    fileprivate var storedScenes: [SceneNumber] {
        didSet {
            defaults.set(storedScenes, forKey: "scenes")
        }
    }
    /// Currently presenting Scene.
    ///
    /// If no current scene, this is set to `.invalidScene`.
    fileprivate var currentScene: SceneNumber
    
    /// Target scene.
    private var targetScene: (scene: SceneNumber, complete: Date)? {
        didSet {
            if let targetScene = targetScene {
               let remainingTime = targetScene.complete.timeIntervalSinceNow
                DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) { [weak self] in
                    self?.currentScene = targetScene.scene
                    self?.targetScene = nil
                }
            }
        }
    }
    /// The last transaction details.
    private let transactionHelper = TransactionHelper()
    
    private let defaults: UserDefaults
    
    private var logger: LoggerDelegate? {
        return MeshNetworkManager.instance.logger
    }
    
    init(_ meshNetwork: MeshNetwork,
         defaultTransitionTimeServer delegate: GenericDefaultTransitionTimeServerDelegate) {
        let types: [StaticMeshMessage.Type] = [
            SceneGet.self,
            SceneRegisterGet.self,
            SceneRecall.self,
            SceneRecallUnacknowledged.self
        ]
        messageTypes = types.toMap()
        
        defaultTransitionTimeServer = delegate
        
        defaults = UserDefaults(suiteName: meshNetwork.uuid.uuidString)!
        storedScenes = defaults.array(forKey: "scenes") as? [SceneNumber] ?? []
        currentScene = .invalidScene
    }
    
    // MARK: - Stored With Scene Status Delegate
    
    func networkDidExitStoredWithSceneState() {
        currentScene = .invalidScene
    }
    
    // MARK: - Message handlers
    
    func model(_ model: Model, didReceiveAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) throws -> MeshResponse {
        switch request {
        case is SceneRegisterGet:
            // When a Scene Server receives a Scene Register Get message, it shall respond
            // with a Scene Register Status message, setting the Status Code field to Success.
            return SceneRegisterStatus(report: currentScene, and: storedScenes)
            
        case let request as SceneRecall:
            // Little validation.
            guard request.scene.isValidSceneNumber else {
                throw ModelError.invalidMessage
            }
            
            // Ignore a repeated request (with the same TID) from the same source
            // and sent to the same destination when it was received within 6 seconds.
            guard transactionHelper.isNewTransaction(request, from: source, to: destination) else {
                fallthrough // such a GOTO!
            }
            
            // When a Scene Server receives a Scene Recall message with a Scene Number value
            // that does not match a Scene Number stored within the Scene Register state,
            // it shall respond with the Scene Status message, setting the Status Code field
            // to Scene Not Found.
            guard storedScenes.contains(request.scene) else {
                return SceneStatus(report: currentScene, with: .sceneNotFound)
            }

            // If the target state is equal to the current state, the transition shall not be
            // started and is considered complete.
            guard currentScene != request.scene else {
                return SceneStatus(report: currentScene)
            }
            
            // When a Scene Server receives a Scene Recall message with a Scene Number value
            // that matches a Scene Number stored within the Scene Register state, it shall
            // perform a Scene Recall operation for a scene memory referred to by the Scene
            // Number and shall respond with a Scene Status message, setting the Status Code
            // field to Success.
            
            /// Message execution delay in 5 millisecond steps. By default 0.
            let delay = request.delay ?? 0
            /// The time that an element will take to transition to the target
            /// state from the present state. If not set, the default transition
            /// time from Generic Default Transition Time Server model is used.
            let transitionTime = request.transitionTime
                .or(defaultTransitionTimeServer.defaultTransitionTime)
            if transitionTime.isImmediate {
                currentScene = request.scene
            } else {
                let complete = Date(timeIntervalSinceNow: transitionTime.interval! + TimeInterval(delay) * 0.005)
                targetScene = (scene: request.scene, complete: complete)
                currentScene = .invalidScene
            }
            // Recall that scene on all Models that support Scenes.
            MeshNetworkManager.instance.localElements
                .flatMap { element in element.models }
                .compactMap { model in model.delegate as? StoredWithSceneModelDelegate }
                .forEach { delegate in
                    delegate.recall(request.scene,
                                    transitionTime: transitionTime,
                                    delay: delay)
                }
            
        case is SceneGet:
            break
                
        default:
            fatalError("Not possible")
        }
        
        // Reply with SceneStatus.
        if let (targetScene, complete) = targetScene {
            let remainingTime = TransitionTime(complete.timeIntervalSinceNow)
            return SceneStatus(report: targetScene, remainingTime: remainingTime)
        }
        return SceneStatus(report: currentScene)
    }
    
    func model(_ model: Model, didReceiveUnacknowledgedMessage message: UnacknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) {
        switch message {
        case let request as SceneRecallUnacknowledged:
            // Little validation.
            guard request.scene.isValidSceneNumber else {
                return
            }
            
            // Ignore a repeated request (with the same TID) from the same source
            // and sent to the same destination when it was received within 6 seconds.
            guard transactionHelper.isNewTransaction(request, from: source, to: destination) else {
                return
            }
            
            // When a Scene Server receives a Scene Recall message with a Scene Number value
            // that does not match a Scene Number stored within the Scene Register state,
            // it shall respond with the Scene Status message, setting the Status Code field
            // to Scene Not Found.
            guard storedScenes.contains(request.scene) else {
                return
            }

            // If the target state is equal to the current state, the transition shall not be
            // started and is considered complete.
            guard currentScene != request.scene else {
                return
            }
            
            // When a Scene Server receives a Scene Recall Unacknowledged message with a
            // Scene Number value that matches a Scene Number stored within the Scene
            // Register state, it shall perform a Scene Recall operation for a scene
            // memory referred to by the Scene Number.
            
            /// Message execution delay in 5 millisecond steps. By default 0.
            let delay = request.delay ?? 0
            /// The time that an element will take to transition to the target
            /// state from the present state. If not set, the default transition
            /// time from Generic Default Transition Time Server model is used.
            let transitionTime = request.transitionTime
                .or(defaultTransitionTimeServer.defaultTransitionTime)
            if transitionTime.isImmediate {
                currentScene = request.scene
            } else {
                let complete = Date(timeIntervalSinceNow: transitionTime.interval! + TimeInterval(delay) * 0.005)
                targetScene = (scene: request.scene, complete: complete)
                currentScene = .invalidScene
            }
            // Recall that scene on all Models that support Scenes.
            MeshNetworkManager.instance.localElements
                .flatMap { element in element.models }
                .compactMap { model in model.delegate as? StoredWithSceneModelDelegate }
                .forEach { delegate in
                    delegate.recall(request.scene,
                                    transitionTime: transitionTime,
                                    delay: delay)
                }
                
        default:
            // Not possible.
            break
        }
    }
    
    func model(_ model: Model, didReceiveResponse response: MeshResponse,
               toAcknowledgedMessage request: AcknowledgedMeshMessage, from source: Address) {
        // Not possible.
    }
    
}

extension SceneSetupServerDelegate {
    
    var storedScenes: [SceneNumber] {
        return server.storedScenes
    }
    
    var currentScene: SceneNumber {
        get { return server.currentScene }
        set { server.currentScene = newValue }
    }
    
    func setCurrentScene(_ scene: SceneNumber) {
        if !server.storedScenes.contains(scene) {
            server.storedScenes.append(scene)
        }
        server.currentScene = scene
    }
    
    func removeScene(at index: Int) {
        let scene = server.storedScenes.remove(at: index)
        if currentScene == scene {
            currentScene = .invalidScene
        }
    }
    
}
