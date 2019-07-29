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
    
    /// Returns whether the Model is subscribed to the given Group.
    ///
    /// This method may also return `true` if the Group is not known
    /// to the local Provisioner and is not returned using `subscriptions`
    /// property.
    ///
    /// - parameter group: The Group to check subscription to.
    /// - returns: `True` if the Model is subscribed to the Group,
    ///            `false` otherwise.
    func isSubscribed(to group: Group) -> Bool {
        return subscribe.contains(group._address)
    }
    
    /// Returns whether the Model is subscribed to the given address.
    ///
    /// This method may also return `true` if the address is not known
    /// to the local Provisioner and is a Group with this address is
    /// not returned using `subscriptions` property.
    /// Moreover, if a Virtual Label of a Group is not known, but the
    /// 16-bit address is known, and the given address contains the Virtual
    /// Label, with the same 16-bit address, this method will return `false`,
    /// as it may not guarantee that the labels are the same.
    ///
    /// - parameter address: The address to check subscription to.
    /// - returns: `True` if the Model is subscribed to a Group with given,
    ///            address, `false` otherwise.
    func isSubscribed(to address: MeshAddress) -> Bool {
        return subscribe.contains(address.hex)
    }
    
}
