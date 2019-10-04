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
        let targetState: T
        let start: Date
        let delay: TimeInterval
        let duration: TimeInterval
        
        var startTime: Date {
            return start.addingTimeInterval(delay)
        }
        
        var remainingTime: TimeInterval {
            let startsIn = startTime.timeIntervalSinceNow
            if startsIn >= 0 {
                return startsIn + duration
            } else if duration - startsIn > 0 {
                return duration - startsIn
            } else {
                return 0.0
            }
        }
    }
    
    /// The current state.
    let state: T
    /// The transition object.
    let transition: Transition?
    
    init(_ state: T) {
        self.state = state
        self.transition = nil
    }
    
    init(transitionFrom state: GenericState<T>, to targetState: T,
         delay: TimeInterval, duration: TimeInterval) {
        self.state = state.state
        guard state.state != targetState else {
            self.transition = nil
            return
        }
        self.transition = Self.Transition(targetState: targetState,
                                          start: Date(), delay: delay,
                                          duration: duration)
    }
    
    init(continueTransitionFrom state: GenericState<T>, to targetState: T,
         delay: TimeInterval, duration: TimeInterval) {
        self.state = state.state
        guard state.state != targetState else {
            self.transition = nil
            return
        }
        if let transition = state.transition {
            self.transition = Self.Transition(targetState: targetState,
                                              start: transition.start, delay: delay,
                                              duration: duration)
        } else {
            self.transition = Self.Transition(targetState: targetState,
                                              start: Date(), delay: delay,
                                              duration: duration)
        }
    }
}


