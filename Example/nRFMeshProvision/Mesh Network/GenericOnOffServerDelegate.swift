//
//  GenericOnOffServerDelegate.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 01/10/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import nRFMeshProvision

class GenericOnOffServerDelegate: ModelDelegate {
    let messageTypes: [UInt32 : MeshMessage.Type]
    
    /// Model state.
    private var state = GenericState<Bool>(false) {
        didSet {
            if let transition = state.transition {
                if transition.remainingTime > 0 {
                    DispatchQueue.main.async {
                        Timer.scheduledTimer(withTimeInterval: transition.remainingTime, repeats: false) { _ in
                            // If the state has not change since it was set,
                            // remove the Transition.
                            if self.state.transition?.start == transition.start {
                                self.state = GenericState<Bool>(self.state.transition?.targetState ?? self.state.state)
                            }
                        }
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
    /// The state observer.
    private var observer: ((GenericState<Bool>) -> ())?
    
    init() {
        let types: [GenericMessage.Type] = [
            GenericOnOffGet.self,
            GenericOnOffSet.self,
            GenericOnOffSetUnacknowledged.self
        ]
        messageTypes = types.toMap()
    }
    
    // MARK: - Message handlers
    
    func handle(acknowledgedMessage request: AcknowledgedMeshMessage,
                sentFrom source: Address, to model: Model) -> MeshMessage {
        switch request {
        case let request as GenericOnOffSet:
            if let transitionTime = request.transitionTime,
               let delay = request.delay {
                state = GenericState<Bool>(transitionFrom: state.state, to: request.isOn,
                                           delay: TimeInterval(delay) * 0.005,
                                           duration: transitionTime.interval)
            } else {
                state = GenericState<Bool>(request.isOn)
            }
            fallthrough
        default:
            if let transition = state.transition, transition.remainingTime > 0 {
                return GenericOnOffStatus(state.state,
                                          targetState: transition.targetState,
                                          remainingTime: TransitionTime(transition.remainingTime))
            } else {
                return GenericOnOffStatus(state.state)
            }
        }
    }
    
    func handle(unacknowledgedMessage message: MeshMessage,
                sentFrom source: Address, to model: Model) {
        switch message {
        case let request as GenericOnOffSetUnacknowledged:
            if let transitionTime = request.transitionTime,
               let delay = request.delay {
                state = GenericState<Bool>(transitionFrom: state.state, to: request.isOn,
                                           delay: TimeInterval(delay) * 0.005,
                                           duration: transitionTime.interval)
            } else {
                state = GenericState<Bool>(request.isOn)
            }
        default:
            break
        }
    }
    
    func handle(response: MeshMessage, toAcknowledgedMessage request: AcknowledgedMeshMessage,
                sentFrom source: Address, to model: Model) {
        // Not possible.
    }
    
    func observe(_ observer: @escaping (GenericState<Bool>) -> ()) {
        self.observer = observer
        observer(state)
    }
    
}
