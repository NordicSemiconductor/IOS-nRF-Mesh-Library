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

public extension Node {
    
    /// Returns weather Composition Data has been applied to the Node.
    var isCompositionDataReceived: Bool {
        return companyIdentifier != nil
    }

    /// Returns whether the Node belongs to one of the Provisioners
    /// of the mesh network.
    var isProvisioner: Bool {
        return meshNetwork?.contains(provisionerWithUuid: uuid) ?? false
    }
    
    /// Returns whether the Node belongs to the main Provisioner.
    /// The main Provisioner will be used to perform all
    /// provisioning and communication on this device. Every device
    /// should use a different Provisioner to set up devices in the
    /// same mesh network to avoid conflicts with addressing nodes.
    var isLocalProvisioner: Bool {
        let localProvisionerUuid = meshNetwork?.localProvisioner?.uuid
        return uuid == localProvisionerUuid
    }
    
    /// The Provisioner that this Node belongs to, or `nil`
    /// if it's not a Provisioner's Node.
    var provisioner: Provisioner? {
        return meshNetwork?.provisioners.first {
            $0.uuid == uuid
        }
    }
    
}
