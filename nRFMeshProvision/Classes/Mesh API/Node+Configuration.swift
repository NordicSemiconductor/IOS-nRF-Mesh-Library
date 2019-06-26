//
//  Node+Configuration.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 19/06/2019.
//

import Foundation

public extension Node {
    
    /// Returns weather Composition Data has been applied to the Node.
    var isConfigured: Bool {
        return companyIdentifier != nil
    }
    
}
