//
//  GenericState.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 03/10/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import nRFMeshProvision

struct GenericState<T> {
    
    struct Transition {
        let targetState: T
        let start: Date
        let duration: TimeInterval
        
        var remainingTime: TimeInterval {
            let startsIn = start.timeIntervalSinceNow
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
    
    init(transitionFrom state: T, to targetState: T, delay: TimeInterval, duration: TimeInterval) {
        self.state = state
        self.transition = GenericState<T>.Transition(targetState: targetState,
                                                     start: Date(timeIntervalSinceNow: delay),
                                                     duration: duration)
    }
}


