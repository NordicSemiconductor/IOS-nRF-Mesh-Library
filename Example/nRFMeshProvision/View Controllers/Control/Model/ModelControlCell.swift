//
//  ModelControlCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 01/10/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

protocol ModelControlDelegate: class {
    func publish(_ message: MeshMessage, description: String, fromModel model: Model)
}

protocol ModelControlCell {
    var model: Model! { set get }
    var delegate: ModelControlDelegate? { get set }
}

class BaseModelControlCell<MD: ModelDelegate>: UICollectionViewCell, ModelControlCell {
    
    // MARK: - Properties
    
    /// The Model.
    var model: Model! {
        didSet {
            modelDelegate = model.delegate as? MD
            setup(modelDelegate)
        }
    }
    /// The Model delegate.
    var modelDelegate: MD?
    weak var delegate: ModelControlDelegate?
    
    // MARK: - Private methods
    
    func setup(_ model: MD?) {
        // Empty.
    }
}
