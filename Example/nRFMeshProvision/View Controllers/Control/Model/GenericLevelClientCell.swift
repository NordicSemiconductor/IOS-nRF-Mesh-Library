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
    
    @IBAction func plusTapped(_ sender: UIButton) {
        publishGenericDeltaMessage(delta: +2048)
    }
    @IBAction func minusTapped(_ sender: UIButton) {
        publishGenericDeltaMessage(delta: -2048)
    }
    
    override func setup(_ handler: GenericLevelClientDelegate?) {
    }
}

private extension GenericLevelClientCell {
    
    func publishGenericDeltaMessage(delta: Int32) {
        let label = delta < 0 ? "Dimming..." : "Brightening..."
        delegate?.publish(GenericDeltaSetUnacknowledged(delta: delta), description: label, fromModel: model)
    }
    
}
