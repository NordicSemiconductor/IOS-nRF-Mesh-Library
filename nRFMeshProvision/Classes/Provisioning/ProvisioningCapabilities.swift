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

/// The device sends this PDU to indicate its supported provisioning
/// capabilities to a Provisioner.
public struct ProvisioningCapabilities {
    /// Number of elements supported by the device.
    public let numberOfElements: UInt8
    /// Supported algorithms and other capabilities.
    public let algorithms:       Algorithms
    /// Supported public key types.
    public let publicKeyType:    PublicKeyType
    /// Supported static OOB Types.
    public let oobType:          OobType
    /// Maximum size of Output OOB supported.
    public let outputOobSize:    UInt8
    /// Supported Output OOB Actions.
    public let outputOobActions: OutputOobActions
    /// Maximum size of Input OOB supported.
    public let inputOobSize:     UInt8
    /// Supported Input OOB Actions.
    public let inputOobActions:  InputOobActions
}

extension ProvisioningCapabilities: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return """
        Number of elements: \(numberOfElements)
        Algorithms: \(algorithms)
        Public Key Type: \(publicKeyType)
        OOB Type: \(oobType)
        Output OOB Size: \(outputOobSize)
        Output OOB Actions: \(outputOobActions)
        Input OOB Size: \(inputOobSize)
        Input OOB Actions: \(inputOobActions)
        """
    }
    
}
