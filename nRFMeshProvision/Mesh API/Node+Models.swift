/*
* Copyright (c) 2023, Nordic Semiconductor
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

public extension Node {
    
    /// Returns whether the Node contains at least one Bluetooth SIG defined Model with
    /// given Model ID on any of its Elements.
    ///
    /// - parameter sigModelId: Bluetooth SIG Model ID.
    /// - returns: `True` if the Node contains at least one Model with given Model ID
    ///            on any of its Elements, `false` otherwise.
    func contains(modelWithSigModelId sigModelId: UInt16) -> Bool {
        return elements.contains(modelWithSigModelId: sigModelId)
    }
    
    /// Returns whether the Node contains at least one Model with given identifier
    /// on any of its Elements.
    ///
    /// - parameter modelId:   The 16-bit Model identifier.
    /// - parameter companyId: The company identifier as defined in Assigned Numbers.
    /// - returns: `True` if the Node contains at least one Model with given Model ID
    ///            on any of its Elements, `false` otherwise.
    /// - seeAlso: https://www.bluetooth.com/specifications/assigned-numbers/company-identifiers/
    func contains(modelWithModelId modelId: UInt16, definedBy companyId: UInt16) -> Bool {
        return elements.contains(modelWithModelId: modelId, definedBy: companyId)
    }
    
    /// Returns whether the Node contains the given Model on any of its Elements.
    ///
    /// - parameter modelId: The Model to look for.
    /// - returns: `True` if the Node contains the given Model on any of its Elements,
    ///            `false` otherwise.
    func contains(model: Model) -> Bool {
        return elements.contains(model: model)
    }
    
    /// Returns list of Models from any Element of the Node matching the given Model ID.
    ///
    /// - parameter sigModelId: Bluetooth SIG Model ID.
    /// - returns: List of Models with the given Model identifier.
    func models(withSigModelId sigModelId: UInt16) -> [Model] {
        return elements.compactMap { $0.model(withSigModelId: sigModelId) }
    }
    
    /// Returns list of Models from any Element of the Node matching the given Model ID.
    ///
    /// - parameter modelId:   The 16-bit Model identifier.
    /// - parameter companyId: The company identifier as defined in Assigned Numbers.
    /// - returns: List of Models with the given Model identifier.
    /// - seeAlso: https://www.bluetooth.com/specifications/assigned-numbers/company-identifiers/
    func models(withModelId modelId: UInt16, definedBy companyId: UInt16) -> [Model] {
        return elements.compactMap { $0.model(withModelId: modelId, definedBy: companyId) }
    }
    
}
