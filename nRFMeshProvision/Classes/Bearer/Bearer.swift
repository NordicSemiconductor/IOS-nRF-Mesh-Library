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
    
    /// This method opens the Bearer.
    func open()
    
    /// This method closes the Bearer.
    func close()
    
    /// This method sends the given data over the bearer.
    /// If the data length exceeds the MTU, it should
    /// be segmented before calling this method.
    ///
    /// - parameter data: The data to be sent over the Bearer.
    func send(_ data: Data)
}

public protocol ProvisioningBearer: Bearer {
    // Empty.
}

public protocol MeshBearer: Bearer {
    // Empty.
}
