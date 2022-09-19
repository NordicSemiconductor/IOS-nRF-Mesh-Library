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

import UIKit

class GenericLevelServerCell: BaseModelControlCell<GenericLevelServerDelegate> {
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var fullIcon: UIImageView!
    
    var progress: UIView!
    
    override func setup(_ model: GenericLevelServerDelegate?) {
        icon.tintColor = .nordicFall
        fullIcon.backgroundColor = .dynamicColor(light: .nordicFall, dark: .darkNordicFall)
        fullIcon.tintColor = .white
        
        progress = UIView(frame: CGRect(x: fullIcon.frame.height, y: 0,
                                        width: fullIcon.frame.width, height: 0))
        progress.backgroundColor = .black
        fullIcon.mask = progress
        
        model?.observe { [weak self] state in
            guard let self = self else { return }
            let width = self.fullIcon.frame.width
            let height = self.fullIcon.frame.height
            if let transition = state.transition {
                let currentValue = state.currentValue
                let targetHeight = ceil(height * (0.5 + CGFloat(transition.targetValue) / (2 * CGFloat(Int16.max))))
                let currentHeight = ceil(height * (0.5 + CGFloat(currentValue) / (2 * CGFloat(Int16.max))))
                let delay = max(transition.startTime.timeIntervalSinceNow, 0.0)
                
                self.progress.layer.removeAllAnimations()
                self.progress.frame = CGRect(x: 0, y: height - currentHeight,
                                             width: width, height: currentHeight)
                UIView.animate(withDuration: transition.remainingTime - delay,
                               delay: delay,
                               options: .curveLinear, animations: { [weak self] in
                    self?.progress.frame = CGRect(x: 0, y: height - targetHeight,
                                                  width: width, height: targetHeight)
                })
            } else if let animation = state.animation {
                let targetValue: Int16 = animation.speed > 0 ? Int16.max : Int16.min
                let currentValue = state.currentValue
                let targetHeight: CGFloat = animation.speed > 0 ? height : 0
                let currentHeight = ceil(height * (0.5 + CGFloat(currentValue) / (2 * CGFloat(Int16.max))))
                let diff = abs(Double(targetValue) - Double(currentValue))
                let duration: TimeInterval = diff / abs(Double(animation.speed))
                let delay = max(animation.startTime.timeIntervalSinceNow, 0.0)
                
                self.progress.layer.removeAllAnimations()
                self.progress.frame = CGRect(x: 0, y: height - currentHeight,
                                             width: width, height: currentHeight)
                UIView.animate(withDuration: duration, delay: delay,
                               options: .curveLinear, animations: { [weak self] in
                    self?.progress.frame = CGRect(x: 0, y: height - targetHeight,
                                                  width: width, height: targetHeight)
                }, completion: { completed in
                    if completed {
                        self.animateMove(speed: animation.speed)
                    }
                })
            } else {
                let targetHeight = ceil(height * (0.5 + CGFloat(state.value) / (2 * CGFloat(Int16.max))))
                self.progress.layer.removeAllAnimations()
                self.progress.frame = CGRect(x: 0, y: height - targetHeight, width: width, height: targetHeight)
            }
        }
    }
    
    private func animateMove(speed: Int16) {
        let width = fullIcon.frame.width
        let height = fullIcon.frame.height
        let currentHeight: CGFloat = speed > 0 ? 0 : height
        let targetHeight: CGFloat = speed > 0 ? height : 0
        let duration: TimeInterval = 2 * Double(Int16.max) / abs(Double(speed))
        
        progress.frame = CGRect(x: 0, y: height - currentHeight,
                                     width: width, height: currentHeight)
        UIView.animate(withDuration: duration, delay: 0,
                       options: .curveLinear, animations: { [weak self] in
            guard let self = self else { return }
            self.progress.frame = CGRect(x: 0, y: height - targetHeight,
                                         width: width, height: targetHeight)
        }, completion: { completed in
            if completed {
                self.animateMove(speed: speed)
            }
        })
    }
}
