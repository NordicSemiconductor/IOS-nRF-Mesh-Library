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
import NordicMesh

extension UInt16 {
    
    /// Nordic Semiconductor Company ID.
    ///
    /// The value is registered with Bluetooth SIG.
    static let nordicSemiconductorCompanyId: UInt16 = 0x0059
    
    // Supported vendor models for Nordic Semiconductor Company ID.
    // See https://docs.nordicsemi.com/bundle/ncs-latest/page/nrf/protocols/bt/bt_mesh/overview/reserved_ids.html
    // for complete list of them.
    static let simpleOnOffServerModelId: UInt16 = 0x0000
    static let simpleOnOffClientModelId: UInt16 = 0x0001
    static let rssiServer: UInt16 = 0x0005
    static let rssiClient: UInt16 = 0x0006
    static let rssiUtil: UInt16 = 0x0007
    static let thingy52Server: UInt16 = 0x0008
    static let thingy52Client: UInt16 = 0x0009
    static let chatClient: UInt16 = 0x000A
    static let distanceMeasurementServer: UInt16 = 0x000B
    static let distanceMeasurementClient: UInt16 = 0x000C
    /// The LE Pairing Initiator model is a vendor model that can be used to obtain
    /// a passkey that will authenticate a Bluetooth LE connection over a mesh network
    /// when it is not possible to use other pairing methods.
    static let lePairingInitiator: UInt16 = 0x000D
    /// The LE Pairing Responder model is a vendor model that can be used to hand over
    /// a passkey that will authenticate a Bluetooth LE connection over a mesh network
    /// when it is not possible to use other pairing methods.
    ///
    /// Read mode in the [Documentation](https://docs.nordicsemi.com/bundle/ncs-latest/page/nrf/libraries/bluetooth/mesh/vnd/le_pair_resp.html#bt-mesh-le-pair-resp-readme).
    static let lePairingResponder: UInt16 = 0x000E
    
}
