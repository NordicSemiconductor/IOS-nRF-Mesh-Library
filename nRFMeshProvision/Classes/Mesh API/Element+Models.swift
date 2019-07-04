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
    
    /// Returns `true` if the Element contains a Model compatible
    /// with given one. Compatible Models make a pair of Client - Server.
    ///
    /// For example, a compatible Model to Generic On/Off Server is
    /// Generic On/Off Client, and vice versa.
    ///
    /// - parameter model: The Model, which pair is required.
    /// - returns: `True`, if the Element has the matching Model.
    func contains(modelCompatibleWith model: Model) -> Bool {
        // Find a Client for a Server, or Server for a Client.
        let compatibleModelId = (model.modelId % 2 == 0) ? model.modelId + 1 : model.modelId - 1
        return models.contains(where: { $0.modelId == compatibleModelId })
    }
    
}
