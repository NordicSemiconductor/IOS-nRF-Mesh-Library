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
                let value = (CGFloat(Int16.max) + CGFloat(transition.targetState)) / (2 * CGFloat(Int16.max))
                let delay = max(transition.startTime.timeIntervalSinceNow, 0.0)
                UIView.animate(withDuration: transition.remainingTime - delay,
                               delay: delay,
                               animations: { [weak self] in
                    guard let self = self else { return }
                                self.progress.frame = CGRect(x: 0, y: height - height * value,
                                                             width: width, height: height * value)
                })
            } else {
                let value = (CGFloat(Int16.max) + CGFloat(state.state)) / (2 * CGFloat(Int16.max))
                self.progress.frame = CGRect(x: 0, y: height - height * value, width: width, height: height * value)
            }
        }
    }
}
