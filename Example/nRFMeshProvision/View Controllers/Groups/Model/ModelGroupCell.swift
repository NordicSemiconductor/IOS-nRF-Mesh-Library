//
//  ModelGroupCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 27/08/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

protocol ModelGroupViewCellDelegate: class {
    /// Encrypts the message with the given Application Key and a Network Key
    /// bound to it, and sends it to the Group.
    ///
    /// - parameter message: The message to be sent.
    /// - parameter description: The message to be displayed for the user.
    /// - parameter applicationKey: The Application Key to sign the message with.
    func send(_ message: MeshMessage, description: String, using applicationKey: ApplicationKey)
}

class ModelGroupCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    var group: Group!
    var applicationKey: ApplicationKey!
    var models: [Model]! {
        didSet {
            reload()
        }
    }
    
    weak var delegate: ModelGroupViewCellDelegate?
    
    // MARK: - Private methods
    
    func reload() {
        // Empty.
    }
}
