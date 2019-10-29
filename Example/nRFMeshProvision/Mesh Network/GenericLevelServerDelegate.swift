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

class GenericLevelServerDelegate: ModelDelegate {
    let messageTypes: [UInt32 : MeshMessage.Type]
    let isSubscriptionSupported: Bool = true
    
    /// Model state.
    private var state = GenericState<Int16>(Int16.min) {
        didSet {
            if let transition = state.transition {
                if transition.remainingTime > 0 {
                    DispatchQueue.main.async {
                        Timer.scheduledTimer(withTimeInterval: transition.remainingTime, repeats: false) { _ in
                            // If the state has not change since it was set,
                            // remove the Transition.
                            if self.state.transition?.start == transition.start {
                                self.state = GenericState<Int16>(self.state.transition?.targetValue ?? self.state.value)
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
    private var observer: ((GenericState<Int16>) -> ())?
    
    init() {
        let types: [GenericMessage.Type] = [
            GenericLevelGet.self,
            GenericLevelSet.self,
            GenericLevelSetUnacknowledged.self,
            GenericDeltaSet.self,
            GenericDeltaSetUnacknowledged.self,
            GenericMoveSet.self,
            GenericMoveSetUnacknowledged.self
        ]
        messageTypes = types.toMap()
    }
    
    // MARK: - Message handlers
    
    func model(_ model: Model, didReceiveAcknowledgedMessage request: AcknowledgedMeshMessage,
               from source: Address, sentTo destination: MeshAddress) -> MeshMessage {
        switch request {
        case let request as GenericLevelSet:
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
                state = GenericState<Int16>(transitionFrom: state, to: request.level,
                                            delay: TimeInterval(delay) * 0.005,
                                            duration: transitionTime.interval)
            } else {
                state = GenericState<Int16>(request.level)
            }

        case let request as GenericDeltaSet:
            let targetLevel = Int16(truncatingIfNeeded: Int32(state.value) + request.delta)
            
            if let transitionTime = request.transitionTime,
               let delay = request.delay {
                // Is the same transaction already in progress?
                if let transition = state.transition, transition.remainingTime > 0,
                   lastTransaction != nil &&
                   lastTransaction!.source == source && lastTransaction!.destination == destination &&
                   !request.isNewTransaction(previousTid: lastTransaction!.tid, timestamp: lastTransaction!.timestamp) {
                    // Continue the same transition.
                    state = GenericState<Int16>(continueTransitionFrom: state, to: targetLevel,
                                                delay: TimeInterval(delay) * 0.005,
                                                duration: transitionTime.interval)
                } else {
                    // Start a new transaction.
                    state = GenericState<Int16>(transitionFrom: state, to: targetLevel,
                                                delay: TimeInterval(delay) * 0.005,
                                                duration: transitionTime.interval)
                }
            } else {
                state = GenericState<Int16>(targetLevel)
            }
            lastTransaction = (source: source, destination: destination, tid: request.tid, timestamp: Date())
            
        case let request as GenericMoveSet:
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
                state = GenericState<Int16>(animateFrom: state, to: request.deltaLevel,
                                            delay: TimeInterval(delay) * 0.005,
                                            duration: transitionTime.interval)
            } else {
                // Generic Default Transition Time is not supported, so the command
                // shall not initiate any change.
            }
            
        default:
            // Not possible.
            break
        }

        // Reply with GenericLevelStatus.
        if let transition = state.transition, transition.remainingTime > 0 {
            return GenericLevelStatus(level: state.value,
                                      targetLevel: transition.targetValue,
                                      remainingTime: TransitionTime(transition.remainingTime))
        } else {
            return GenericLevelStatus(level: state.value)
        }
    }
    
    func model(_ model: Model, didReceiveUnacknowledgedMessage message: MeshMessage,
               from source: Address, sentTo destination: MeshAddress) {
        switch message {
        case let request as GenericLevelSetUnacknowledged:
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
                state = GenericState<Int16>(transitionFrom: state, to: request.level,
                                            delay: TimeInterval(delay) * 0.005,
                                            duration: transitionTime.interval)
            } else {
                state = GenericState<Int16>(request.level)
            }

        case let request as GenericDeltaSetUnacknowledged:
            let targetLevel = Int16(truncatingIfNeeded: Int32(state.value) + request.delta)
            
            if let transitionTime = request.transitionTime,
               let delay = request.delay {
                // Is the same transaction already in progress?
                if let transition = state.transition, transition.remainingTime > 0,
                   lastTransaction != nil &&
                   lastTransaction!.source == source && lastTransaction!.destination == destination &&
                   !request.isNewTransaction(previousTid: lastTransaction!.tid, timestamp: lastTransaction!.timestamp) {
                    // Continue the same transition.
                    state = GenericState<Int16>(continueTransitionFrom: state, to: targetLevel,
                                                delay: TimeInterval(delay) * 0.005,
                                                duration: transitionTime.interval)
                } else {
                    // Start a new transaction.
                    state = GenericState<Int16>(transitionFrom: state, to: targetLevel,
                                                delay: TimeInterval(delay) * 0.005,
                                                duration: transitionTime.interval)
                }
            } else {
                state = GenericState<Int16>(targetLevel)
            }
            lastTransaction = (source: source, destination: destination, tid: request.tid, timestamp: Date())
                
        case let request as GenericMoveSetUnacknowledged:
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
                state = GenericState<Int16>(animateFrom: state, to: request.deltaLevel,
                                            delay: TimeInterval(delay) * 0.005,
                                            duration: transitionTime.interval)
            } else {
                // Generic Default Transition Time is not supported, so the command
                // shall not initiate any change.
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
    func observe(_ observer: @escaping (GenericState<Int16>) -> ()) {
        self.observer = observer
        observer(state)
    }
    
}
