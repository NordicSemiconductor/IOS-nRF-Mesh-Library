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

class BaseModelControlCell<MH: ModelHandler>: UICollectionViewCell, ModelControlCell {
    
    // MARK: - Properties
    
    /// The Model.
    var model: Model! {
        didSet {
            handler = model.handler as? MH
            setup(handler)
        }
    }
    /// The Model Handler.
    var handler: MH?
    weak var delegate: ModelControlDelegate?
    
    // MARK: - Private methods
    
    func setup(_ handler: MH?) {
        // Empty.
    }
}
