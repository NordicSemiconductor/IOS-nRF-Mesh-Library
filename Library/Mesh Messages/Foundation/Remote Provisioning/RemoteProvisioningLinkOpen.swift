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

/// A Remote Provisioning Link Open message is an acknowledged message used by the
/// Remote Provisioning Client to establish the provisioning bearer between a node
/// supporting the Remote Provisioning Server model and an unprovisioned device,
/// or to open the Node Provisioning Protocol Interface.
public struct RemoteProvisioningLinkOpen: AcknowledgedRemoteProvisioningMessage {
    public static let opCode: UInt32 = 0x8059
    public static let responseType: StaticMeshResponse.Type = RemoteProvisioningLinkStatus.self
    
    /// Device UUID.
    public let uuid: UUID?
    /// Link open timeout in seconds.
    ///
    /// This field is optional if `uuid` is present; otherwise should be set to `nil`.
    ///
    /// The default value of the Timeout parameter is 10 seconds.
    /// Minimum timeout is 1 second. Maximum value is 60 seconds.
    public let timeout: TimeInterval?
    /// Node Provisioning Protocol Interface procedure.
    ///
    /// This field is mandatory if `uuid` is `nil`; otherwise should be excluded.
    public let nppiProcedure: NodeProvisioningProtocolInterfaceProcedure?
    
    public var parameters: Data? {
        if let uuid = uuid {
            if let timeout = timeout {
                return uuid.data + UInt8(timeout)
            }
            return uuid.data
        }
        if let nppiProcedure = nppiProcedure {
            return Data([nppiProcedure.rawValue])
        }
        return nil
    }
    
    /// Creates Remote Provisioning Link Open message.
    ///
    /// - parameters:
    ///   - uuid: The UUID of the device to open link to.
    ///   - timeout: Optional timeout. Minimum value is 1 second and maximum 60 seconds.
    ///              The timeout will be rounded to nearest lower integer.
    public init(uuid: UUID, timeout: TimeInterval? = nil) {
        self.uuid = uuid
        self.timeout = timeout.map { max(1.0, min(60.0, $0)) }
        self.nppiProcedure = nil
    }
    
    
    /// Creates Remote Provisioning Link Open message.
    ///
    /// - parameter nppiProcedure: The Node Provisioning Protocol procedure.
    public init(nppiProcedure: NodeProvisioningProtocolInterfaceProcedure) {
        self.uuid = nil
        self.timeout = nil
        self.nppiProcedure = nppiProcedure
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 1 || parameters.count == 16 || parameters.count == 17 else {
            return nil
        }
        if parameters.count == 1 {
            guard let nppiProcedure = NodeProvisioningProtocolInterfaceProcedure(rawValue: parameters[0]) else {
                return nil
            }
            self.uuid = nil
            self.timeout = nil
            self.nppiProcedure = nppiProcedure
        } else {
            guard let uuid = UUID(data: parameters.subdata(in: 0 ..< 16)) else {
                return nil
            }
            self.uuid = uuid
            self.nppiProcedure = nil
            if parameters.count == 17 {
                let timeout = parameters[16]
                guard timeout > 0 && timeout <= 60 else {
                    return nil
                }
                self.timeout = TimeInterval(timeout)
            } else {
                self.timeout = nil
            }
        }
    }
}
