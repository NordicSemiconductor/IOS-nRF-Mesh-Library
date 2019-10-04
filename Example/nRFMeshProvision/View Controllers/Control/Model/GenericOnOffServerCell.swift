//
//  GenericOnOffServerCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 01/10/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class GenericOnOffServerCell: BaseModelControlCell<GenericOnOffServerDelegate> {
    
    @IBOutlet weak var icon: UIImageView!
    
    override func setup(_ model: GenericOnOffServerDelegate?) {
        icon.tintColor = .nordicSun
        icon.tintAdjustmentMode = .dimmed
        
        model?.observe { [weak self] state in
            guard let self = self else { return }
            self.icon.tintAdjustmentMode = state.state ? .normal : .dimmed
            if let transition = state.transition {
                let delay = max(transition.startTime.timeIntervalSinceNow, 0.0)
                UIView.animate(withDuration: transition.remainingTime - delay,
                               delay: delay,
                               animations: { [weak self] in
                    guard let self = self else { return }
                    self.icon.tintAdjustmentMode = transition.targetState ? .normal : .dimmed
                })
            }
        }
    }
}
