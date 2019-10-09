//
//  GenericOnOffCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 01/10/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class GenericOnOffClientCell: BaseModelControlCell<GenericOnOffClientDelegate> {
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var onButton: UIButton!
    @IBAction func onTapped(_ sender: UIButton) {
        publishGenericOnOffMessage(turnOn: true)
    }
    @IBOutlet weak var offButton: UIButton!
    @IBAction func offTapped(_ sender: UIButton) {
        publishGenericOnOffMessage(turnOn: false)
    }
    
    override func setup(_ model: GenericOnOffClientDelegate?) {
        // On iOS 12.x tinted icons are initially black.
        // Forcing adjustment mode fixes the bug.
        icon.tintAdjustmentMode = .normal
        
        let localProvisioner = MeshNetworkManager.instance.meshNetwork?.localProvisioner
        let isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
        
        onButton.isEnabled = isEnabled
        offButton.isEnabled = isEnabled
    }
}

private extension GenericOnOffClientCell {
    
    func publishGenericOnOffMessage(turnOn: Bool) {
        let label = turnOn ? "Turning ON..." : "Turning OFF..."
        delegate?.publish(GenericOnOffSetUnacknowledged(turnOn,
                                                        transitionTime: TransitionTime(1.0),
                                                        delay: 20), // 100 ms
                          description: label, fromModel: model)
    }
    
}
