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

struct GenericState<T: Equatable> {
    
    struct Transition {
        let targetValue: T
        let start: Date
        let delay: TimeInterval
        let duration: TimeInterval
        
        var startTime: Date {
            return start.addingTimeInterval(delay)
        }
        
        var remainingTime: TimeInterval {
            let startsIn = startTime.timeIntervalSinceNow
            if startsIn + duration > 0 {
                return startsIn + duration
            } else {
                return 0.0
            }
        }
    }
    
    struct Move {
        let start: Date
        let delay: TimeInterval
        // Change of value per second.
        let speed: T
        
        var startTime: Date {
            return start.addingTimeInterval(delay)
        }
    }
    
    /// The current state.
    let value: T
    /// The transition object.
    let transition: Transition?
    /// The animation object.
    let animation: Move?
    
    init(_ state: T) {
        self.value = state
        self.transition = nil
        self.animation = nil
    }
    
    init(transitionFrom state: GenericState<T>, to targetValue: T,
         delay: TimeInterval, duration: TimeInterval) {
        self.value = state.value
        self.animation = nil
        guard state.value != targetValue else {
            self.transition = nil
            return
        }
        self.transition = Self.Transition(targetValue: targetValue,
                                          start: Date(), delay: delay,
                                          duration: duration)
    }
    
    init(continueTransitionFrom state: GenericState<T>, to targetValue: T,
         delay: TimeInterval, duration: TimeInterval) {
        self.value = state.value
        self.animation = nil
        guard state.value != targetValue else {
            self.transition = nil
            return
        }
        if let transition = state.transition {
            self.transition = Self.Transition(targetValue: targetValue,
                                              start: transition.start, delay: delay,
                                              duration: duration)
        } else {
            self.transition = Self.Transition(targetValue: targetValue,
                                              start: Date(), delay: delay,
                                              duration: duration)
        }
    }
    
}

extension GenericState where T: BinaryInteger {
    
    init(animateFrom state: GenericState<T>, to targetValue: T,
         delay: TimeInterval, duration: TimeInterval) {
        self.value = state.value
        self.transition = nil
        guard state.value != targetValue, duration > 0 else {
            self.animation = nil
            return
        }
        let speed = Double(targetValue) / duration
        self.animation = Self.Move(start: Date(), delay: delay,
                                   speed: T(truncatingIfNeeded: Int(speed)))
    }
    
    var currentValue: T {
        if let animation = animation {
            let timeDiff = animation.startTime.timeIntervalSinceNow
            
            // Is the animation scheduled for the future?
            if timeDiff >= 0 {
                return value
            } else {
                // Otherwise, it has already started.
                return T(truncatingIfNeeded: Int(Double(value) - timeDiff * Double(animation.speed)))
            }
        } else if let transition = transition {
            let timeDiff = transition.startTime.timeIntervalSinceNow
            
            // Is the animation scheduled for the future?
            if timeDiff >= 0 {
                return value
            } else if transition.remainingTime == 0 {
                // Has if completed?
                return transition.targetValue
            } else {
                // Otherwise, it's in progress.
                let progress = transition.remainingTime / transition.duration
                let diff = Double(value) - Double(transition.targetValue)
                return T(truncatingIfNeeded: Int(transition.targetValue) + Int(diff * progress))
            }
        } else {
            return value
        }
    }
}


