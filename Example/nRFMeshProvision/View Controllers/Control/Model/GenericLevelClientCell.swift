//
//  GenericLevelClientCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 01/10/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class GenericLevelClientCell: BaseModelControlCell<GenericLevelClientDelegate> {
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var plusButton: UIButton!
    @IBAction func plusTapped(_ sender: UIButton) {
        publishGenericDeltaMessage(delta: +8192)
    }
    @IBOutlet weak var minusButton: UIButton!
    @IBAction func minusTapped(_ sender: UIButton) {
        publishGenericDeltaMessage(delta: -8192)
    }
    
    override func setup(_ model: GenericLevelClientDelegate?) {
        // On iOS 12.x tinted icons are initially black.
        // Forcing adjustment mode fixes the bug.
        icon.tintAdjustmentMode = .normal
        
        let localProvisioner = MeshNetworkManager.instance.meshNetwork?.localProvisioner
        let isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
        
        plusButton.isEnabled = isEnabled
        minusButton.isEnabled = isEnabled
    }
}

private extension GenericLevelClientCell {
    
    func publishGenericDeltaMessage(delta: Int32) {
        let label = delta < 0 ? "Dimming..." : "Brightening..."
        delegate?.publish(GenericDeltaSetUnacknowledged(delta: delta,
                                                        transitionTime: TransitionTime(1.0),
                                                        delay: 20), // 100 ms
                          description: label, fromModel: model)
    }
    
}
