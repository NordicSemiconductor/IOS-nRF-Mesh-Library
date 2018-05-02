//
//  ProxyScannerCell.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 30/04/2018.
//  Copyright © 2018 NordicSemiconductor ASA. All rights reserved.
//

import UIKit
import nRFMeshProvision

class ProxyScannerCell: UITableViewCell {
    @IBOutlet weak var nodeName: UILabel!
    @IBOutlet weak var nodeRSSI: UILabel!
    @IBOutlet weak var advertisementData: UILabel!
    
    public func showNode(_ aNode: UnprovisionedMeshNode) {
        nodeName.text = aNode.nodeBLEName()
        advertisementData.text = aNode.humanReadableNodeIdentifier()
        if aNode.RSSI() != 127 {
            nodeRSSI.textColor = UIColor.black
            nodeRSSI.text = "\(aNode.RSSI()) dB"
        } else {
            if nodeRSSI.text == "RSSI" {
                nodeRSSI.text = nil
            }
            nodeRSSI.textColor = UIColor.gray
        }
    }
}
