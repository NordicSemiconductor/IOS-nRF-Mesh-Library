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
    /// The last transaction details.
    private var lastTransaction: (source: Address, destination: MeshAddress, tid: UInt8, timestamp: Date)?
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
    
    func model(_ model: Model, didReceiveAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) -> MeshMessage {
        switch request {
        case let request as GenericOnOffSet:
        // Ignore a repeated request (with the same TID) from the same source
        // and sent to the same destinatino when it was received within 6 seconds.
            guard lastTransaction == nil ||
                  lastTransaction!.source != source || lastTransaction!.destination != destination ||
                  request.isNewTransaction(previousTid: lastTransaction!.tid, timestamp: lastTransaction!.timestamp) else {
                    lastTransaction = (source: source, destination: destination, tid: request.tid, timestamp: Date())
                break
            }
            lastTransaction = (source: source, destination: destination, tid: request.tid, timestamp: Date())
            
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
        
        // Reply with GenericOnOffStatus.
        if let transition = state.transition, transition.remainingTime > 0 {
            return GenericOnOffStatus(state.state,
                                      targetState: transition.targetState,
                                      remainingTime: TransitionTime(transition.remainingTime))
        } else {
            return GenericOnOffStatus(state.state)
        }
    }
    
    func model(_ model: Model, didReceiveUnacknowledgedMessage message: MeshMessage,
               from source: Address, sentTo destination: MeshAddress) {
        switch message {
        case let request as GenericOnOffSetUnacknowledged:
            // Ignore a repeated request (with the same TID) from the same source
            // and sent to the same destinatino when it was received within 6 seconds.
            guard lastTransaction == nil ||
                  lastTransaction!.source != source || lastTransaction!.destination != destination ||
                  request.isNewTransaction(previousTid: lastTransaction!.tid, timestamp: lastTransaction!.timestamp) else {
                lastTransaction = (source: source, destination: destination, tid: request.tid, timestamp: Date())
                break
            }
            lastTransaction = (source: source, destination: destination, tid: request.tid, timestamp: Date())
            
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
