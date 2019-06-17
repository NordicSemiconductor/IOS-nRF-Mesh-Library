//
//  Element+Address.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 11/06/2019.
//

import Foundation

public extension Element {
    
    /// Returns the Unicast Address of the Element.
    /// For Elements not added to Node this returns the Element index
    /// value as `Address`.
    var unicastAddress: Address {
        return parentNode?.unicastAddress ?? 0 + Address(index)
    }
    
}
