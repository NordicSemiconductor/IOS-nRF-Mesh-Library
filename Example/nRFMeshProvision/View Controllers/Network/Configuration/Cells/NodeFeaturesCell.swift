//
//  NodeFeaturesCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 20/06/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class NodeFeaturesCell: UITableViewCell {
    @IBOutlet weak var relayLabel: UILabel!
    @IBOutlet weak var friendLabel: UILabel!
    @IBOutlet weak var proxyLabel: UILabel!
    @IBOutlet weak var lowPowerLabel: UILabel!
    
    var node: Node! {
        didSet {
            relayLabel.text = node.features?.relay?.debugDescription ?? "Unknown"
            proxyLabel.text = node.features?.proxy?.debugDescription ?? "Unknown"
            friendLabel.text = node.features?.friend?.debugDescription ?? "Unknown"
            lowPowerLabel.text = node.features?.lowPower?.debugDescription ?? "Unknown"
        }
    }
    
}
