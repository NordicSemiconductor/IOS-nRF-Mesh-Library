//
//  CustomAddressCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 17/09/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

protocol CustomAddressDelegate: class {
    func customAddressEditingDidBegin()
    func customAddressDidChange(_ address: Address?)
}

class CustomAddressCell: UITableViewCell {

    @IBOutlet weak var addressField: UITextField!
    
    @IBAction func editingDidBegin(_ sender: UITextField) {
        accessoryType = .checkmark
        delegate?.customAddressEditingDidBegin()
    }
    
    @IBAction func editingDidEnd(_ sender: UITextField) {
        delegate?.customAddressDidChange(Address(sender.text!, radix: 16))
    }
    
    weak var delegate: CustomAddressDelegate?
}
