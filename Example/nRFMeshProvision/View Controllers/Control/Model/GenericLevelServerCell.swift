//
//  GenericLevelServerCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 01/10/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

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
                    guard let self = self else { return }
                    self.progress.frame = CGRect(x: 0, y: height - targetHeight,
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
                    guard let self = self else { return }
                    self.progress.frame = CGRect(x: 0, y: height - targetHeight,
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
