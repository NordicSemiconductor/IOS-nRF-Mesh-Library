//
//  Element+Address.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 11/06/2019.
//

import Foundation

public extension Element {
    
    /// Returns the Unicast Address of the Element.
    var unicastAddress: Address {
        return parentNode.unicastAddress + Address(index)
    }
    
}
