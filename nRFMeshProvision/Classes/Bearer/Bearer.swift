//
//  Bearer.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

public protocol Bearer: class {
    /// The Bearer delegate object will receive callbacks whenever the
    /// Bearer state changes or a message is received from the Bearer.
    var delegate: BearerDelegate? { get set }
    /// Returns whether the Bearer supports provisioning.
    var isProvisioningSupported: Bool { get }
    
    /// This method opens the Bearer.
    func open()
    
    /// This method closes the Bearer.
    func close()
    
    /// This method sends the given data over the bearer.
    /// Data longer than MTU will automatically be segmented
    /// using the bearer protocol if bearer implements segmentation.
    ///
    /// - parameter data: The data to be sent over the Bearer.
    func send(_ data: Data)
}

public extension Bearer {
    
    var isProvisioningSupported: Bool {
        return false
    }
    
}

public protocol MeshBearer: Bearer {
    // Empty.
}

public protocol ProvisioningBearer: Bearer {
    // Empty.
}

public extension ProvisioningBearer {
    
    var isProvisioningSupported: Bool {
        return true
    }
    
}
