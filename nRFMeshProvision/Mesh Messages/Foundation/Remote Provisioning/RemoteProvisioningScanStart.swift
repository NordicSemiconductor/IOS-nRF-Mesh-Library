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
import CoreBluetooth

/// A Remote Provisioning Scan Start message is an acknowledged message that is
/// used by the Remote Provisioning Client to start the Remote Provisioning Scan
/// procedure, which finds unprovisioned devices within immediate radio range of
/// the Remote Provisioning Server.
public struct RemoteProvisioningScanStart: AcknowledgedRemoteProvisioningMessage {
    public static let opCode: UInt32 = 0x8052
    public typealias ResponseType = RemoteProvisioningScanStatus
    
    /// Maximum number of scanned items to be reported.
    ///
    /// Value 0 indicates that the Remote Provisioning Client does not set a limit
    /// on the number of unprovisioned devices that the Remote Provisioning Server can
    /// report.
    public let scannedItemsLimit: UInt8
    /// Time limit for a scan (in seconds).
    ///
    /// The value will be rounded down to whole seconds.
    public let timeout: TimeInterval
    /// If the UUID field is present, the Remote Provisioning Client is requesting
    /// a Single Device Scanning procedure (i.e., a scan for a specific unprovisioned
    /// device identified by the value of the UUID field). If the UUID field is absent,
    /// the Remote Provisioning Client is requesting a scan for all unprovisioned
    /// devices within immediate radio range (a Multiple Devices Scanning).
    public let uuid: CBUUID?
    
    public var parameters: Data? {
        let data = Data([scannedItemsLimit, UInt8(timeout)])
        if let uuid = uuid {
            return data + uuid.data
        }
        return data
    }
    
    /// Creates Remote Provisioning Scan Start message.
    ///
    /// - parameters:
    ///   - scannedItemsLimit: Maximum number of scanned items to be reported. Value 0
    ///                        indicates no limit.
    ///   - timeout: Time limit for a scan (in seconds). The value will be rounded down
    ///              to whole seconds.
    ///   - uuid: Optional UUID to start a Single Device Scanning procedure.
    public init(scannedItemsLimit: UInt8 = 0, timeout: TimeInterval = 0, uuid: CBUUID? = nil) {
        self.scannedItemsLimit = scannedItemsLimit
        self.timeout = timeout
        self.uuid = uuid
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 2 || parameters.count == 18 else {
            return nil
        }
        scannedItemsLimit = parameters[0]
        timeout = TimeInterval(parameters[1])
        if parameters.count == 18 {
            uuid = CBUUID(data: parameters.subdata(in: 2 ..< 18))
        } else {
            uuid = nil
        }
    }
}
