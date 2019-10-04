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
    
    @IBAction func onTapped(_ sender: UIButton) {
        publishGenericOnOffMessage(turnOn: true)
    }
    @IBAction func offTapped(_ sender: UIButton) {
        publishGenericOnOffMessage(turnOn: false)
    }
}

private extension GenericOnOffClientCell {
    
    func publishGenericOnOffMessage(turnOn: Bool) {
        let label = turnOn ? "Turning ON..." : "Turning OFF..."
        delegate?.publish(GenericOnOffSetUnacknowledged(turnOn,
                                                        transitionTime: TransitionTime(1.0),
                                                        delay: 100),
                          description: label, fromModel: model)
    }
    
}
