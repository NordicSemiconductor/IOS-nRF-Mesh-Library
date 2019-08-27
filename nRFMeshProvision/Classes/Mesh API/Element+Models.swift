//
//  Element+Models.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 03/07/2019.
//

import Foundation

public extension Element {
    
    /// Returns the first found Bluetooth SIG defined Model with given identifier.
    ///
    /// - parameter sigModelId: The 16-bit Model identifier as defined in the
    ///                         Bluetooth Mesh Model specification.
    /// - returns: The Model found, or `nil` if no such exist.
    func model(withSigModelId sigModelId: UInt16) -> Model? {
        return models.first {
            $0.isBluetoothSIGAssigned && $0.modelIdentifier == sigModelId
        }
    }
    
    /// Returns the first found Model with given identifier.
    ///
    /// - parameter sigModelId: The 32-bit Model identifier.
    /// - returns: The Model found, or `nil` if no such exist.
    func model(withModelId modelId: UInt32) -> Model? {
        return models.first {
            $0.modelId == modelId
        }
    }
    
    /// Returns the first found Model with given identifier.
    ///
    /// - parameter sigModelId: The 16-bit Model identifier.
    /// - parameter companyId:  The company identifier as defined in Assigned Numbers.
    /// - returns: The Model found, or `nil` if no such exist.
    /// - seeAlso: https://www.bluetooth.com/specifications/assigned-numbers/company-identifiers/
    func model(withModelId modelId: UInt16, definedBy companyId: UInt16) -> Model? {
        return models.first {
            $0.companyIdentifier == companyId && $0.modelIdentifier == modelId
        }
    }
    
    /// Returns whether the Element contains a Model with given Model ID.
    ///
    /// - parameter modelId: The Model ID to look for.
    /// - returns: `True` if the Element contains a Model with given Model ID,
    ///            `false` otherwise.
    func contains(modelWithId modelId: UInt32) -> Bool {
        return models.contains { $0.modelId == modelId }
    }
    
    /// Returns whether the Element contains a Model with given Model identifier.
    ///
    /// - parameter modelIdentifier: Bluetooth SIG or vendor-assigned model
    ///                              identifier.
    /// - returns: `True` if the Element contains a Model with given Model
    ///            identifier, `false` otherwise.
    func contains(modelWithIdentifier modelIdentifier: UInt16) -> Bool {
        return models.contains { $0.modelIdentifier == modelIdentifier }
    }
    
    /// Returns whether the Element contains the given Model.
    ///
    /// - parameter modelId: The Model to look for.
    /// - returns: `True` if the Element contains the given Model, `false` otherwise.
    func contains(model: Model) -> Bool {
        return models.contains(model)
    }
    
    /// Returns `true` if the Element contains a Model compatible
    /// with given one. Compatible Models make a pair of Client - Server.
    ///
    /// For example, a compatible Model to Generic On/Off Server is
    /// Generic On/Off Client, and vice versa.
    ///
    /// - parameter model:          The Model, which pair is required.
    /// - parameter applicationKey: The Application Key which the Model
    ///                             must be bound to.
    /// - returns: `True`, if the Element has the matching Model.
    func contains(modelCompatibleWith model: Model, boundTo applicationKey: ApplicationKey) -> Bool {
        return models.contains { $0.isCompatible(to: model) && $0.bind.contains(applicationKey.index) }
    }
    
    /// Returns whether the Element contains any Models that are
    /// subscribed to the given Group.
    ///
    /// - parameter group: The Group to look for.
    /// - returns: `True`, if the Element contains at least one Model
    ///            that is subscribed to the given Group, `false` otherwise.
    func contains(modelSubscribedTo group: Group) -> Bool {
        return models.contains { $0.subscriptions.contains(group) }
    }
    
    /// Returns list of Models belonging to this Element that are
    /// subscribed to the given Group.
    ///
    /// - parameter group: The Group to look for.
    /// - returns: List of Models that are subscribed to the given Group.
    func models(subscribedTo group: Group) -> [Model] {
        return models.filter { $0.subscriptions.contains(group) }
    }
    
}

public extension Array where Element == MeshElement {
    
    /// Returns whether any of Elements in the array contains a Model with given
    /// Model ID.
    ///
    /// - parameter modelId: The Model ID to look for.
    /// - returns: `True` if the array contains an Element with a Model with
    ///            given Model ID, `false` otherwise.
    func contains(modelWithId modelId: UInt32) -> Bool {
        return contains {
            $0.models.contains(where: { $0.modelId == modelId })
        }
    }
    
    /// Returns whether any of Elements in the array contains a Model with given
    /// Model identifier.
    ///
    /// - parameter modelIdentifier: Bluetooth SIG or vendor-assigned model
    ///                              identifier.
    /// - returns: `True` if the array contains an Element with a Model with
    ///            given Model identifier, `false` otherwise.
    func contains(modelWithIdentifier modelIdentifier: UInt16) -> Bool {
        return contains {
            $0.models.contains(where: { $0.modelIdentifier == modelIdentifier })
        }
    }
    
    /// Returns whether the Element contains the given Model.
    ///
    /// - parameter modelId: The Model to look for.
    /// - returns: `True` if the Element contains the given Model, `false` otherwise.
    func contains(model: Model) -> Bool {
        return contains {
            $0.contains(model: model)
        }
    }
    
    /// Returns whether the Element contains any Models that are
    /// subscribed to the given Group.
    ///
    /// - parameter group: The Group to look for.
    /// - returns: `True`, if the Element contains at least one Model
    ///            that is subscribed to the given Group, `false` otherwise.
    func contains(modelSubscribedTo group: Group) -> Bool {
        return contains {
            $0.models.contains { $0.subscriptions.contains(group) }
        }
    }
    
    /// Returns list of Models belonging to any of the Elements in the list
    /// that are subscribed to the given Group.
    ///
    /// - parameter group: The Group to look for.
    /// - returns: List of Models that are subscribed to the given Group.
    func models(subscribedTo group: Group) -> [Model] {
        return flatMap {
            $0.models.filter { $0.subscriptions.contains(group) }
        }
    }
    
}
