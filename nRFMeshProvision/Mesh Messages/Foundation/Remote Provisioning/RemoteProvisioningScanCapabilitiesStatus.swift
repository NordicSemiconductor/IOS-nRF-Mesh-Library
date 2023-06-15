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

/// A Remote Provisioning Scan Capabilities Status message is an unacknowledged
/// message used by the Remote Provisioning Server to report the current value of
/// the Remote Provisioning Scan Capabilities state of a Remote Provisioning Server.
public struct RemoteProvisioningScanCapabilitiesStatus: RemoteProvisioningResponse {
    public static let opCode: UInt32 = 0x8050
    
    /// The maximum number of UUIDs that can be reported during scanning.
    ///
    /// The minimum value of the state is 4. The maximum value of the state is 255.
    public let maxScannedItems: UInt8
    /// Indication if active scan is supported.
    public let activeScanSupported: Bool
    
    public var parameters: Data? {
        return Data([maxScannedItems]) + activeScanSupported
    }
    
    /// Creates a Remote Provisioning Scan Capabilities Status message.
    ///
    /// - parameters:
    ///   - maxScannerItems: The maximum number of UUIDs that can be reported during
    ///                      scanning. The minimum value of the state is 4.
    ///                      The maximum value of the state is 255.
    ///   - activeScanSupported: Whether the Remote Provisioning Server supports
    ///                          active scanning.
    public init?(maxScannedItems: UInt8, activeScanSupported: Bool) {
        guard maxScannedItems >= 4 else {
            return nil
        }
        self.maxScannedItems = maxScannedItems
        self.activeScanSupported = activeScanSupported
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 2 else {
            return nil
        }
        let count = parameters[0]
        guard count >= 4 else {
            return nil
        }
        maxScannedItems = count
        activeScanSupported = parameters[1] == 0x01
    }
}
