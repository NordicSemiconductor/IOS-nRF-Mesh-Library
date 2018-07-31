//
//  ToggleSettingsTableViewCell.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 30/07/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

class ToggleSettingsTableViewCell: UITableViewCell {
    
    //MARK: - Properties
    private var delegate: ToggleSettingsCellDelegate?
    
    //MARK: - Outlets and actions
    @IBAction func toggleSwitchDidChangeValue(_ sender: Any) {
        delegate?.didToggle(toggleSwitch.isOn)
    }

    @IBOutlet weak var toggleSwitch: UISwitch!
    @IBOutlet weak var titleLabel: UILabel!
    
    //MARK: - Implementation
    func setDelegate(_ aDelegate: ToggleSettingsCellDelegate) {
        delegate = aDelegate
    }
}
