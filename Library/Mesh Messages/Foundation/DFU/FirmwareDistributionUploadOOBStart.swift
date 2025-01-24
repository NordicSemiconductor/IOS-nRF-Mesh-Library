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

/// The Firmware Distribution Upload OOB Start message is an acknowledged message sent by
/// a Firmware Distribution Client to start a firmware image upload to a Firmware Distribution Server
/// using an Out of Band (OOB) mechanism.
public struct FirmwareDistributionUploadOOBStart: StaticAcknowledgedMeshMessage {
    public static let opCode: UInt32 = 0x8320
    public static let responseType: StaticMeshResponse.Type = FirmwareDistributionUploadStatus.self
    
    /// URI for the firmware image check and retrieval.
    ///
    /// The URI shall point to a location where the Distributor can check for a newer firmware
    /// image and its retrieval.
    ///
    /// The maximum length of the URI is 255 bytes using UTF-8 encoding.
    let uri: URL
    /// The current Firmware ID of a Target Node(s).
    ///
    /// The Firmware ID, together with the URI, will be used to check whether there is a newer
    /// firmware for the device. The result will be returned using the ``FirmwareDistributionUploadStatus``
    /// message.
    ///
    /// If the URI scheme is `https://`, the FWID will be appended to the URI
    /// using `/check?cfwid=<FWID as hex>` to check the availability of a new firmware image over HTTP
    /// and `/get?cfwid=<FWID as hex>` to retrieve the firmware.
    let currentFirmwareId: FirmwareId
    
    public var parameters: Data? {
        let uriData = uri.absoluteString.data(using: .utf8)!
        return Data([UInt8(uriData.count)]) + uriData + currentFirmwareId.companyIdentifier + currentFirmwareId.version
    }
    
    /// Creates the Firmware Distribution Upload OOB Start message.
    ///
    /// The Firmware ID, together with the URI, will be used to check whether there is a newer
    /// firmware for the device. The result will be returned using the ``FirmwareDistributionUploadStatus``
    /// message.
    ///
    /// If the URI scheme is `https://`, the FWID will be appended to the URI
    /// using `/check?cfwid=<FWID as hex>` to check the availability of a new firmware image over HTTP
    /// and `/get?cfwid=<FWID as hex>` to retrieve the firmware.
    ///
    /// - parameters:
    ///   - uri: URI for the firmware image check and retrieval.
    ///   - currentFirmwareId: The current Firmware ID of a Target Node(s).
    public init(uri: URL, currentFirmwareId: FirmwareId) {
        self.uri = uri
        self.currentFirmwareId = currentFirmwareId
    }
    
    public init?(parameters: Data) {
        // One byte for URI length, at least one byte for the URI and at least 2 bytes for the
        // Firmware ID (Company ID).
        guard parameters.count >= 4 else {
            return nil
        }
        let uriLength = Int(parameters[0])
        guard uriLength >= 1, parameters.count >= 3 + uriLength else {
            return nil
        }
        let uriData = parameters.subdata(in: 1..<uriLength + 1)
        guard let uriString = String(data: uriData, encoding: .utf8),
              let uri = URL(string: uriString) else {
            return nil
        }
        self.uri = uri
        
        let companyIdentifier: UInt16 = parameters.read(fromOffset: 1 + uriLength)
        if parameters.count > 3 + uriLength {
            let version = parameters.subdata(in: 3 + uriLength + 2..<parameters.count)
            self.currentFirmwareId = FirmwareId(companyIdentifier: companyIdentifier, version: version)
        } else {
            self.currentFirmwareId = FirmwareId(companyIdentifier: companyIdentifier, version: Data())
        }
    }
}
