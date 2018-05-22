//
//  MeshNodeLogTableViewCell.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 19/01/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

class MeshNodeLogTableViewCell: UITableViewCell {

    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!

    public func setLogMessage(_ aMessage: String, withTimestamp aTimestamp: Date) {
        messageLabel.text = aMessage
        timestampLabel.text = DateFormatter.localizedString(from: aTimestamp, dateStyle: .none, timeStyle: .medium)
    }
}
