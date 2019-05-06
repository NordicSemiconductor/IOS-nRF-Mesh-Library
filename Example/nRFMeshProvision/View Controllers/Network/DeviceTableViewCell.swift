//
//  DeviceTableViewCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import CoreBluetooth
import nRFMeshProvision

class DeviceTableViewCell: UITableViewCell {

    //MARK: - Outlets and Actions
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var uuid: UILabel!
    @IBOutlet weak var rssiIcon: UIImageView!
    
    // MARK: - Properties
    
    private var lastUpdateTimestamp = Date()
    
    // MARK: - Implementation
    
    func setupView(withDevice device: UnprovisionedDevice, andRSSI rssi: Int) {
        name.text = device.name ?? "Unknown Device"
        uuid.text = device.uuid.uuidString
        
        switch rssi {
        case -128:
            rssiIcon.image = nil
        case -127 ..< -80:
            rssiIcon.image = #imageLiteral(resourceName: "rssi_1")
        case -80 ..< -60:
            rssiIcon.image = #imageLiteral(resourceName: "rssi_2")
        case -60 ..< -40:
            rssiIcon.image = #imageLiteral(resourceName: "rssi_3")
        default:
            rssiIcon.image = #imageLiteral(resourceName: "rssi_4")
        }
    }
    
    func deviceDidUpdate(_ device: UnprovisionedDevice, andRSSI rssi: Int) {
        if Date().timeIntervalSince(lastUpdateTimestamp) > 1.0 {
            lastUpdateTimestamp = Date()
            setupView(withDevice: device, andRSSI: rssi)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                guard let self = self else { return }
                if Date().timeIntervalSince(self.lastUpdateTimestamp) > 4.5 {
                    self.setupView(withDevice: device, andRSSI: -128)
                }
            }
        }
    }

}
