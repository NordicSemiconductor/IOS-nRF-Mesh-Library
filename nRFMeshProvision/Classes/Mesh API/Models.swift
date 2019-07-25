//
//  Models.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 25/07/2019.
//

import Foundation

public extension Model {
    
    /// Returns whether the given Model is compatible with the one.
    ///
    /// A compatible Models create a Client-Server pair. I.e., the
    /// Generic On/Off Client is compatible to Generic On/Off Server,
    /// and vice versa. The rule is that the Server Model has an even
    /// Model ID and the Client Model has Model ID greater by 1.
    ///
    /// - parameter model: The Model to compare to.
    /// - returns: `True`, if the Models are compatible, `false` otherwise.
    func isCompatible(to model: Model) -> Bool {
        let compatibleModelId = (modelId % 2 == 0) ? modelId + 1 : modelId - 1
        return model.modelId == compatibleModelId
    }
    
}
