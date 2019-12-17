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
        return subscriptions.contains(where: { $0.address == address })
    }
    
}
