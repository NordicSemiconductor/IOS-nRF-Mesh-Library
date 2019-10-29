//
//  ProvisioningViewDelegate.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 16/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import nRFMeshProvision

protocol ProvisioningViewDelegate: class {
    
    /// Callback called when a new device has been provisioned.
    func provisionerDidProvisionNewDevice(_ node: Node)
    
}
