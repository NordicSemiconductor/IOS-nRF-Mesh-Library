//
//  Model+Keys.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 02/07/2019.
//

import Foundation

public extension Model {
    
    /// List of Application Keys bound to this Model.
    ///
    /// The list will not contain unknown Application Keys bound
    /// to this Model, possibly bound by other Provisioner.
    var boundApplicationKeys: [ApplicationKey] {
        return parentElement?.parentNode?.applicationKeys.filter({ bind.contains($0.index) }) ?? []
    }
    
    /// Whether the given Application Key is bound to this Model.
    ///
    /// - parameter applicationKey: The key to check.
    /// - returns: `True` if the key is bound to this Model,
    ///            otherwise `false`.
    func isBoundTo(_ applicationKey: ApplicationKey) -> Bool {
        return bind.contains(applicationKey.index)
    }
}
