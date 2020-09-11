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

class GenericOnOffServerDelegate: StoredWithSceneModelDelegate {
    let messageTypes: [UInt32 : MeshMessage.Type]
    let isSubscriptionSupported: Bool = true
    
    lazy var publicationMessageComposer: MessageComposer? = { [unowned self] in
        if let transition = self.state.transition, transition.remainingTime > 0 {
            return GenericOnOffStatus(self.state.value,
                                      targetState: transition.targetValue,
                                      remainingTime: TransitionTime(transition.remainingTime))
        } else {
            return GenericOnOffStatus(self.state.value)
        }
    }
    
    /// States stored with Scenes.
    ///
    /// The key is the Scene number as HEX (4-character hexadecimal string).
    private var storedScenes: [String: Bool]
    /// User defaults are used to store state with Scenes.
    private let defaults: UserDefaults
    /// The key, under which scenes are stored.
    private let key: String
    
    /// Model state.
    private var state = GenericState<Bool>(false) {
        willSet {
            // If the state has changed due to a different reason than
            // recalling a Scene, the Current Scene in Scene Server model
            // has to be invalidated.
            if !newValue.storedWithScene,
               let network = MeshNetworkManager.instance.meshNetwork {
                networkDidExitStoredWithSceneState(network)
            }
        }
        didSet {
            if let transition = state.transition, transition.remainingTime > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + transition.remainingTime) { [weak self] in
                    guard let self = self else { return }
                    // If the state has not change since it was set,
                    // remove the Transition.
                    if self.state.transition?.start == transition.start {
                        self.state = GenericState<Bool>(self.state.transition?.targetValue ?? self.state.value)
                    }
                }
            }
            let state = self.state
            if let observer = observer {
                DispatchQueue.main.async {
                    observer(state)
                }
            }
        }
    }
    /// The last transaction details.
    private let transactionHelper = TransactionHelper()
    /// The state observer.
    private var observer: ((GenericState<Bool>) -> ())?
    
    init(_ meshNetwork: MeshNetwork, elementIndex: UInt8) {
        let types: [GenericMessage.Type] = [
            GenericOnOffGet.self,
            GenericOnOffSet.self,
            GenericOnOffSetUnacknowledged.self
        ]
        messageTypes = types.toMap()
        
        defaults = UserDefaults(suiteName: meshNetwork.uuid.uuidString)!
        key = "genericOnOffServer_\(elementIndex)_scenes"
        storedScenes = defaults.dictionary(forKey: key) as? [String: Bool] ?? [:]
    }
    
    // MARK: - Scene hanlders
    
    func store(with scene: SceneNumber) {
        storedScenes[scene.hex] = state.value
        defaults.set(storedScenes, forKey: key)
    }
    
    func recall(_ scene: SceneNumber, transitionTime: TransitionTime?, delay: UInt8?) {
        guard let isOn = storedScenes[scene.hex] else {
            return
        }
        if let transitionTime = transitionTime,
           let delay = delay {
            state = GenericState<Bool>(transitionFrom: state, to: isOn,
                                       delay: TimeInterval(delay) * 0.005,
                                       duration: transitionTime.interval,
                                       storedWithScene: true)
        } else {
            state = GenericState<Bool>(isOn, storedWithScene: true)
        }
    }
    
    // MARK: - Message handlers
    
    func model(_ model: Model, didReceiveAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) -> MeshMessage {
        switch request {
        case let request as GenericOnOffSet:
            // Ignore a repeated request (with the same TID) from the same source
            // and sent to the same destination when it was received within 6 seconds.
            guard transactionHelper.isNewTransaction(request, from: source, to: destination) else {
                break
            }
            
            if let transitionTime = request.transitionTime,
               let delay = request.delay {
                state = GenericState<Bool>(transitionFrom: state, to: request.isOn,
                                           delay: TimeInterval(delay) * 0.005,
                                           duration: transitionTime.interval)
            } else {
                state = GenericState<Bool>(request.isOn)
            }
            
        default:
            fatalError("Not possible")
        }
        
        // Reply with GenericOnOffStatus.
        if let transition = state.transition, transition.remainingTime > 0 {
            return GenericOnOffStatus(state.value,
                                      targetState: transition.targetValue,
                                      remainingTime: TransitionTime(transition.remainingTime))
        } else {
            return GenericOnOffStatus(state.value)
        }
    }
    
    func model(_ model: Model, didReceiveUnacknowledgedMessage message: MeshMessage,
               from source: Address, sentTo destination: MeshAddress) {
        switch message {
        case let request as GenericOnOffSetUnacknowledged:
            // Ignore a repeated request (with the same TID) from the same source
            // and sent to the same destination when it was received within 6 seconds.
            guard transactionHelper.isNewTransaction(request, from: source, to: destination) else {
                break
            }
            
            if let transitionTime = request.transitionTime,
               let delay = request.delay {
                state = GenericState<Bool>(transitionFrom: state, to: request.isOn,
                                           delay: TimeInterval(delay) * 0.005,
                                           duration: transitionTime.interval)
            } else {
                state = GenericState<Bool>(request.isOn)
            }
            
        default:
            // Not possible.
            break
        }
    }
    
    func model(_ model: Model, didReceiveResponse response: MeshMessage,
               toAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address) {
        // Not possible.
    }
    
    /// Sets a model state observer.
    ///
    /// - parameter observer: The observer that will be informed about
    ///                       state changes.
    func observe(_ observer: @escaping (GenericState<Bool>) -> ()) {
        self.observer = observer
        observer(state)
    }
    
}
