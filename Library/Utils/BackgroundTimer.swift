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

internal class BackgroundTimer {
    private let timer: DispatchSourceTimer
    
    let interval: TimeInterval
    let repeats: Bool
    
    /// Schedules a timer that can be started from a background DispatchQueue.
    @discardableResult
    static func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool,
                               queue: DispatchQueue = DispatchQueue.global(qos: .background),
                               block: @escaping  (BackgroundTimer) -> Void) -> BackgroundTimer {
        return BackgroundTimer(withTimeInterval: interval, repeats: repeats, queue: queue, block: block)
    }
    
    private init(withTimeInterval interval: TimeInterval, repeats: Bool,
                 queue: DispatchQueue, block: @escaping  (BackgroundTimer) -> Void) {
        self.interval = interval
        self.repeats = repeats
        
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer.setEventHandler {
            block(self)
            if !repeats {
                self.invalidate()
            }
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
        timer.setEventHandler {}
        timer.cancel()
    }
    
}
