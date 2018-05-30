//
//  ToggleControlTableViewCell.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 28/05/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

class ToggleControlTableViewCell: UITableViewCell {
    // MARK: - Properties
    public var delegate: ToggleCellDelegate?
    // MARK: - Outlets and actions
    @IBOutlet weak var stateLabel   : UILabel!
    @IBOutlet weak var toggleSwitch : UISwitch!
    @IBAction func didSwitchToggleState(_ sender: Any) {
        self.handleSwitchStateChange(isOn: toggleSwitch.isOn)
    }

    // MARK: - Implementation
    public func setTitle(aTitle: String) {
        stateLabel.text = aTitle
    }

    private func handleSwitchStateChange(isOn: Bool) {
        delegate?.didToggleCell(aCell: self, didSetOnStateTo: isOn)
    }
}
