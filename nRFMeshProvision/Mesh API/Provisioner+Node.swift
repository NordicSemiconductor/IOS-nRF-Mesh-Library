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

public extension Provisioner {
    
    /// The Primary Unicast Address of the Provisioner.
    ///
    /// The Provisioner must be added to a mesh network and
    /// must have a Unicast Address assigned, otherwise `nil`
    /// is returned instead.
    @available(*, deprecated, renamed: "primaryUnicastAddress")
    var unicastAddress: Address? {
        return node?.primaryUnicastAddress
    }
    
    /// The Primary Unicast Address of the Provisioner.
    ///
    /// The Provisioner must be added to a mesh network and
    /// must have a Unicast Address assigned, otherwise `nil`
    /// is returned instead.
    ///
    /// - since: 4.0.0
    var primaryUnicastAddress: Address? {
        return node?.primaryUnicastAddress
    }
    
    /// The Provisioner's Node, if such exists, otherwise `nil`.
    var node: Node? {
        return meshNetwork?.node(for: self)
    }
    
    /// Whether the Provisioner can send and receive mesh messages.
    ///
    /// To have configuration capabilities the Provisioner must have
    /// a Unicast Address assigned, therefore it is a Node in the
    /// network.
    var hasConfigurationCapabilities: Bool {
        return node != nil
    }
    
    /// Whether the Provisioner is the one currently set
    /// as a local Provisioner.
    var isLocal: Bool {
        return meshNetwork?.isLocalProvisioner(self) ?? false
    }
    
}
