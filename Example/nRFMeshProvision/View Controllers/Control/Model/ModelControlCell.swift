//
//  ModelControlCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 01/10/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

protocol ModelControlCell {
    var model: Model! { set get }
}

class BaseModelControlCell<MH: ModelHandler>: ProgressCollectionViewCell, ModelControlCell {
    
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
    
    // MARK: - Private methods
    
    func setup(_ handler: MH?) {
        // Empty.
    }
}
