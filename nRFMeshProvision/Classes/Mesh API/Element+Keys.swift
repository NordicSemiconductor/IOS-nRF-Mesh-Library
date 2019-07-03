//
//  Element+Keys.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 01/07/2019.
//

import Foundation

public extension Element {
    
    /// Returns whether any of the Element's Models are bound to the
    /// guven Application Key.
    ///
    /// - parameter applicationKey: The Application Key to check bindings.
    /// - returns: `True` if there is at least one Model bound to the given
    ///            Application Key, `false` otherwise.
    func hasModelBoundTo(_ applicationKey: ApplicationKey) -> Bool {
        return models.contains {
            $0.bind.contains(applicationKey.index)
        }
    }
    
}
