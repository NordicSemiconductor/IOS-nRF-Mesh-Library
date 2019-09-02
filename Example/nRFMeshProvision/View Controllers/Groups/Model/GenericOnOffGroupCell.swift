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
    
    @IBOutlet weak var onButton: UIButton!
    @IBAction func onTapped(_ sender: UIButton) {
        sendGenericOnOffMessage(turnOn: true)
    }
    @IBOutlet weak var offButton: UIButton!
    @IBAction func offTapped(_ sender: UIButton) {
        sendGenericOnOffMessage(turnOn: false)
    }
    
    // MARK: - Implementation
    
    override func reload() {
        let numberOfDevices = models.count
        if numberOfDevices == 1 {
            title.text = "1 device"
        } else {
            title.text = "\(numberOfDevices) devices"
        }
        
        let localProvisioner = MeshNetworkManager.instance.meshNetwork?.localProvisioner
        let isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
        
        onButton.isEnabled = isEnabled
        offButton.isEnabled = isEnabled
    }    
}

private extension GenericOnOffGroupCell {
    
    func sendGenericOnOffMessage(turnOn: Bool) {
        let label = turnOn ? "Turning ON..." : "Turning OFF..."
        delegate?.send(GenericOnOffSetUnacknowledged(turnOn), description: label, using: applicationKey)
    }
    
}
