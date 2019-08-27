//
//  GroupCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 18/07/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class GroupCell: UITableViewCell {
    
    // MARK: - Outlets & Actions
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    // - MARK: - Properties
    
    var group: Group! {
        didSet {
            nameLabel.text = group.name
            addressLabel.text = group.address.asString()
        }
    }
}
