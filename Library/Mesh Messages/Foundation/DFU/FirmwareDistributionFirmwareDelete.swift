/*
* Copyright (c) 2025, Nordic Semiconductor
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

/// The Firmware Distribution Firmware Delete message is an acknowledged message sent by
/// a Firmware Distribution Client to delete a stored firmware image on a Firmware Distribution Server.
public struct FirmwareDistributionFirmwareDelete: StaticAcknowledgedMeshMessage {
    public static let opCode: UInt32 = 0x8325
    public static let responseType: StaticMeshResponse.Type = FirmwareDistributionFirmwareStatus.self
    
    /// Identifies the firmware image to delete.
    public let firmwareId: FirmwareId
    
    public var parameters: Data? {
        return Data() + firmwareId.companyIdentifier + firmwareId.version
    }
    
    /// Creates the Firmware Distribution Firmware Delete message.
    ///
    /// - parameter firmwareId: The Firmware ID identifying the firmware image to delete.
    public init(_ firmwareId: FirmwareId) {
        self.firmwareId = firmwareId
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 2 else {
            return nil
        }
        let companyIdentifier: UInt16 = parameters.read(fromOffset: 0)
        if parameters.count == 2 {
            self.firmwareId = FirmwareId(companyIdentifier: companyIdentifier, version: Data())
        } else {
            let version = parameters.subdata(in: 2..<parameters.count)
            self.firmwareId = FirmwareId(companyIdentifier: companyIdentifier, version: version)
        }
    }
}
