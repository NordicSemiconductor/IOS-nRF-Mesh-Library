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

public extension Model {
    
    /// List of Application Keys bound to this Model.
    ///
    /// The list will not contain unknown Application Keys bound
    /// to this Model, possibly bound by other Provisioner.
    ///
    /// If the Node does not belong to any mesh network, this method returns an empty array.
    /// In that case use ``Model/isBoundTo(_:)`` instead.
    var boundApplicationKeys: [ApplicationKey] {
        return parentElement?.parentNode?.applicationKeys
            .filter { isBoundTo($0) } ?? []
    }
    
    /// Whether the given Application Key is bound to this Model.
    ///
    /// - note: Only the Key Index is used for key comparison.
    ///
    /// - parameter applicationKey: The key to check.
    /// - returns: `True` if the key is bound to this Model,
    ///            otherwise `false`.
    func isBoundTo(_ applicationKey: ApplicationKey) -> Bool {
        return bind.contains(applicationKey.index)
    }
    
    /// Whether the model supports App Key binding.
    ///
    /// Models that do not support App Key binding use Device Key on access layer security.
    /// - since: 4.0.0 
    var supportsApplicationKeyBinding: Bool {
        return !requiresDeviceKey
    }
    
}
