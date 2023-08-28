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

/// A Remote Provisioning PDU Report message is an unacknowledged message used by
/// the Remote Provisioning Server to report the Provisioning PDU that either was
/// received from the device being provisioned or was generated locally during the
/// Device Key Refresh procedure, the Node Address Refresh procedure, or the
/// Node Composition Refresh procedure.
public struct RemoteProvisioningPDUReport: UnacknowledgedRemoteProvisioningMessage {
    public static let opCode: UInt32 = 0x805F
    
    /// Number of received Provisioning PDUs.
    public let inboundPduNumber: UInt8
    /// The `response` field identifies the Provisioning PDU that was sent
    /// by an unprovisioned device or generated locally during the
    /// ``NodeProvisioningProtocolInterfaceProcedure/deviceKeyRefresh`` procedure,
    /// the ``NodeProvisioningProtocolInterfaceProcedure/nodeAddressRefresh`` procedure,
    /// or the ``NodeProvisioningProtocolInterfaceProcedure/nodeCompositionRefresh`` procedure.
    public let response: ProvisioningResponse
    
    public var parameters: Data? {
        return Data([inboundPduNumber]) + response.pdu
    }
    
    /// Creates a Remote Provisioning PDU Report message.
    ///
    /// - parameters:
    ///   - inboundPduNumber: The value of the Remote Provisioning Inbound PDU Count state.
    ///   - response: Provisioning response.
    public init(inboundPduNumber: UInt8, response: ProvisioningResponse) {
        self.inboundPduNumber = inboundPduNumber
        self.response = response
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 2 else {
            return nil
        }
        self.inboundPduNumber = parameters[0]
        let pdu = parameters.subdata(in: 1..<parameters.count)
        guard let response = try? ProvisioningResponse(from: pdu) else {
            return nil
        }
        self.response = response
    }
}
