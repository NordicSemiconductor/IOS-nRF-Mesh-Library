//
//  BackgroundTimer.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 19/09/2019.
//

import Foundation

internal class BackgroundTimer {
    private let timer: DispatchSourceTimer
    
    let interval: TimeInterval
    let repeats: Bool
    
    /// Chedules a timer that can be started from a background DispatchQueue.
    @discardableResult static func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool,
                               block: @escaping  (BackgroundTimer) -> Void) -> BackgroundTimer {
        return BackgroundTimer(withTimeInterval: interval, repeats: repeats, block: block)
    }
    
    private init(withTimeInterval interval: TimeInterval, repeats: Bool,
                 block: @escaping  (BackgroundTimer) -> Void) {
        self.interval = interval
        self.repeats = repeats
        
        timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
        timer.setEventHandler {
            block(self)
            self.invalidate()
        }
        if repeats {
            timer.schedule(deadline: .now() + interval, repeating: interval)
        } else {
            timer.schedule(deadline: .now() + interval)
        }
        timer.resume()
    }
    
    deinit {
        timer.setEventHandler {}
        timer.cancel()
    }
    
    /// Asynchronously cancels the dispatch source, preventing any further invocation
    /// of its event handler block.
    func invalidate() {
        timer.cancel()
    }
    
}
