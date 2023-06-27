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

/// A Remote Provisioning Scan Status message is an unacknowledged message used by
/// the Remote Provisioning Server to report the current value of the
/// Remote Provisioning Scan Parameters state and the Remote Provisioning Scan state
/// of a Remote Provisioning Server model.
public struct RemoteProvisioningScanStatus: RemoteProvisioningResponse, RemoteProvisioningStatusMessage {
    public static let opCode: UInt32 = 0x8054
    
    public let status: RemoteProvisioningMessageStatus
    /// The Remote Provisioning Scan state.
    public let scanningState: RemoteProvisioningScanState
    /// Maximum number of scanned items to be reported.
    ///
    /// Value 0 indicates that the Remote Provisioning Client does not set a limit
    /// on the number of unprovisioned devices that the Remote Provisioning Server can
    /// report.
    public let scannedItemsLimit: UInt8
    /// Current value of the time limit for a scan (in seconds).
    ///
    /// The value will be rounded down to whole seconds.
    public let timeout: TimeInterval
    
    public var parameters: Data? {
        return Data([status.rawValue, scanningState.rawValue, scannedItemsLimit, UInt8(timeout)])
    }
    
    /// Creates a Remote Provisioning Scan Status message.
    ///
    /// - parameters:
    ///   - status: Operation status.
    ///   - scanningState: The Remote Provisioning Scan state.
    ///   - scannedItemsLimit: Maximum number of scanned items to be reported.
    ///   - timeout: Current value of the time limit for a scan (in seconds).
    public init(
        status: RemoteProvisioningMessageStatus,
        scanningState: RemoteProvisioningScanState,
        scannedItemsLimit: UInt8,
        timeout: TimeInterval
    ) {
        self.status = status
        self.scanningState = scanningState
        self.scannedItemsLimit = scannedItemsLimit
        self.timeout = timeout
    }
    
    public init(confirm request: RemoteProvisioningScanStart) {
        status = .success
        scanningState = request.uuid == nil ? .multipleDeviceScan : .singleDeviceScan
        scannedItemsLimit = request.scannedItemsLimit
        timeout = request.timeout
    }
    
    public init(confirm request: RemoteProvisioningScanStop) {
        status = .success
        scanningState = .idle
        scannedItemsLimit = 0
        timeout = 0
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 4 else {
            return nil
        }
        guard let status = RemoteProvisioningMessageStatus(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        guard let scanningState = RemoteProvisioningScanState(rawValue: parameters[1]) else {
            return nil
        }
        self.scanningState = scanningState
        self.scannedItemsLimit = parameters[2]
        self.timeout = TimeInterval(parameters[3])
    }
}
