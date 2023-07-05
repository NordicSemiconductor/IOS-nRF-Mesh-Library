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

/// A Remote Provisioning Link Status message is an unacknowledged message used by
/// the Remote Provisioning Server to acknowledge a Remote Provisioning Link Get
/// message, a Remote Provisioning Link Open message, or a Remote Provisioning
/// Link Close message.
public struct RemoteProvisioningLinkStatus: RemoteProvisioningResponse,
                                            RemoteProvisioningStatusMessage,
                                            RemoteProvisioningLinkStateMessage {
    public static let opCode: UInt32 = 0x805B
    
    public let status: RemoteProvisioningMessageStatus
    public let linkState: RemoteProvisioningLinkState
    
    public var parameters: Data? {
        return Data([status.rawValue, linkState.rawValue])
    }
    
    public init(status: RemoteProvisioningMessageStatus, linkState: RemoteProvisioningLinkState) {
        self.status = status
        self.linkState = linkState
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 2 else {
            return nil
        }
        guard let status = RemoteProvisioningMessageStatus(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        guard let linkState = RemoteProvisioningLinkState(rawValue: parameters[1]) else {
            return nil
        }
        self.linkState = linkState
    }
}
