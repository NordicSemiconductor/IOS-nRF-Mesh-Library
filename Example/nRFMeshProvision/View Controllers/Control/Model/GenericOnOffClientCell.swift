//
//  GenericOnOffCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 01/10/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class GenericOnOffClientCell: BaseModelControlCell<GenericOnOffClientHandler> {
    
    @IBAction func onTapped(_ sender: UIButton) {
        start("Turning ON...") {
            return self.handler?.set(true, acknowledged: self.model.parentElement.index > 0)
        }
    }
    @IBAction func offTapped(_ sender: UIButton) {
        start("Turning OFF...") {
            return self.handler?.set(false, acknowledged: self.model.parentElement.index > 0)
        }
    }
    
    override func setup(_ handler: GenericOnOffClientHandler?) {
        
    }
}
