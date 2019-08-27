//
//  GenericOnOffGroupCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 27/08/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class GenericOnOffGroupCell: ModelGroupCell {
    
    // MARK: - Outlets and Actions
    
    @IBOutlet weak var title: UILabel!
    
    @IBAction func onTapped(_ sender: UIButton) {
        sendGenericOnOffMessage(turnOn: true)
    }
    @IBAction func offTapped(_ sender: UIButton) {
        sendGenericOnOffMessage(turnOn: false)
    }
    
    // MARK: - Implementation
    
}

private extension GenericOnOffGroupCell {
    
    func sendGenericOnOffMessage(turnOn: Bool) {
        let label = turnOn ? "Turning ON..." : "Turning OFF..."
        delegate?.send(GenericOnOffSetUnacknowledged(turnOn), description: label, using: applicationKey)
    }
    
}
