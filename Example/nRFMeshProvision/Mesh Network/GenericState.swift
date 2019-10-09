//
//  GenericState.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 03/10/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

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


