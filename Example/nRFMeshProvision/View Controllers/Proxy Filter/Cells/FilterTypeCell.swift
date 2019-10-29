//
//  FilterTypeCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 16/09/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

protocol ProxyFilterTypeDelegate: class {
    func filterTypeDidChange(_ type: ProxyFilerType)
}

class FilterTypeCell: UITableViewCell {
    
    // MARK: - Outlets and Actions

    @IBOutlet weak var filterTypeControl: UISegmentedControl!
    
    @IBAction func filterTypeDidChange(_ sender: UISegmentedControl) {
        type = ProxyFilerType(rawValue: UInt8(sender.selectedSegmentIndex)) ?? .whitelist
        delegate?.filterTypeDidChange(type)
    }
    
    // MARK: - Properties
    
    weak var delegate: ProxyFilterTypeDelegate?
    
    var type: ProxyFilerType = .whitelist {
        didSet {
            filterTypeControl.selectedSegmentIndex = Int(type.rawValue)
        }
    }
    
}
