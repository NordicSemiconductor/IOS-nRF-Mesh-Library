/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

public extension Element {
    
    /// Returns the first found Model with given identifier.
    ///
    /// - parameter sigModelId: The 32-bit Model identifier.
    /// - returns: The Model found, or `nil` if no such exist.
    func model(withModelId modelId: UInt32) -> Model? {
        return models.first {
            $0.modelId == modelId
        }
    }
    
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
    /// - parameter modelId:   The 16-bit Model identifier.
    /// - parameter companyId: The company identifier as defined in Assigned Numbers.
    /// - returns: The Model found, or `nil` if no such exist.
    /// - seeAlso: https://www.bluetooth.com/specifications/assigned-numbers/company-identifiers/
    func model(withModelId modelId: UInt16, definedBy companyId: UInt16) -> Model? {
        return models.first {
            $0.companyIdentifier == companyId && $0.modelIdentifier == modelId
        }
    }
    
    /// Returns list of Models belonging to this Element bound to the
    /// given Application Key.
    ///
    /// - parameter applicationKey: The Application Key which the Models
    ///                             must be bound to.
    /// - returns: List of Models belonging to this Element bound to the
    ///            given Application Key.
    func models(boundTo applicationKey: ApplicationKey) -> [Model] {
        return models.filter { $0.bind.contains(applicationKey.index) }
    }
    
    /// Returns list of Models belonging to this Element that are
    /// subscribed to the given Group.
    ///
    /// - parameter group: The Group to look for.
    /// - returns: List of Models that are subscribed to the given Group.
    func models(subscribedTo group: Group) -> [Model] {
        return models.filter { $0.subscriptions.contains(group) }
    }
    
    /// Returns whether the Element contains a Model with given Model ID.
    ///
    /// - parameter modelId: The Model ID to look for.
    /// - returns: `True` if the Element contains a Model with given Model ID,
    ///            `false` otherwise.
    func contains(modelWithId modelId: UInt32) -> Bool {
        return models.contains { $0.modelId == modelId }
    }
    
    /// Returns whether the Element contains a Bluetooth SIG defined Model with
    /// given Model ID.
    ///
    /// - parameter sigModelId: Bluetooth SIG Model ID.
    /// - returns: `True` if the Element contains a Model with given Model ID,
    ///            `false` otherwise.
    func contains(modelWithSigModelId sigModelId: UInt16) -> Bool {
        return models.contains {
            $0.isBluetoothSIGAssigned && $0.modelIdentifier == sigModelId
        }
    }
    
    /// Returns whether the Element contains a Model with given identifier.
    ///
    /// - parameter modelId:   The 16-bit Model identifier.
    /// - parameter companyId: The company identifier as defined in Assigned Numbers.
    /// - returns: `True` if the Element contains a Model with given Model ID,
    ///            `false` otherwise.
    /// - seeAlso: https://www.bluetooth.com/specifications/assigned-numbers/company-identifiers/
    func contains(modelWithModelId modelId: UInt16, definedBy companyId: UInt16) -> Bool {
        return models.contains {
            $0.companyIdentifier == companyId && $0.modelIdentifier == modelId
        }
    }
    
    /// Returns whether the Element contains the given Model.
    ///
    /// - parameter modelId: The Model to look for.
    /// - returns: `True` if the Element contains the given Model, `false` otherwise.
    func contains(model: Model) -> Bool {
        return models.contains(model)
    }
    
    /// Returns `true` if the Element contains a Model bound to the
    /// given Application Key.
    ///
    /// - parameter applicationKey: The Application Key which the Model
    ///                             must be bound to.
    /// - returns: `True`, if the Element has the matching Model.
    func contains(modelBoundTo applicationKey: ApplicationKey) -> Bool {
        return models.contains { $0.bind.contains(applicationKey.index) }
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
            $0.contains(modelWithId: modelId)
        }
    }
    
    /// Returns whether any of Elements in the array contains a Model with given
    /// Model identifier.
    ///
    /// - parameter sigModelId: Bluetooth SIG model identifier.
    /// - returns: `True` if the array contains an Element with a Model with
    ///            given Model identifier, `false` otherwise.
    func contains(modelWithSigModelId sigModelId: UInt16) -> Bool {
        return contains {
            $0.contains(modelWithSigModelId: sigModelId)
        }
    }
    
    /// Returns the first found Model with given identifier.
    ///
    /// - parameter modelId:   The 16-bit Model identifier.
    /// - parameter companyId: The company identifier as defined in Assigned Numbers.
    /// - returns: `True` if the array contains an Element with a Model with
    ///            given Model identifier, `false` otherwise.
    /// - seeAlso: https://www.bluetooth.com/specifications/assigned-numbers/company-identifiers/
    func contains(modelWithModelId modelId: UInt16, definedBy companyId: UInt16) -> Bool {
        return contains {
            $0.contains(modelWithModelId: modelId, definedBy: companyId)
        }
    }
    
    /// Returns whether any of Elements in the array contains a Model with given
    /// Model identifier.
    ///
    /// - parameter modelIdentifier: Bluetooth SIG or vendor-assigned model
    ///                              identifier.
    /// - returns: `True` if the array contains an Element with a Model with
    ///            given Model identifier, `false` otherwise.
    @available(*, deprecated, renamed: "contains(modelWithModelId:definedBy:)")
    func contains(modelWithIdentifier modelIdentifier: UInt16) -> Bool {
        return contains {
            $0.models.contains { $0.modelIdentifier == modelIdentifier }
        }
    }
    
    /// Returns whether the Element contains the given Model.
    ///
    /// - parameter model: The Model to look for.
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
