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

/// The Firmware Distribution Upload Start message is an acknowledged message sent by
/// a Firmware Distribution Client to start a firmware image upload to a Firmware Distribution Server.
public struct FirmwareDistributionUploadStart: StaticAcknowledgedMeshMessage {
    public static let opCode: UInt32 = 0x831F
    public static let responseType: StaticMeshResponse.Type = FirmwareDistributionUploadStatus.self
    
    /// Time To Live (TTL) value used in a firmware image upload.
    ///
    /// Valid values are in the range 0...127 (`0x00 - 0x7F`). Value 255 (`0xFF`) means that
    /// the default TTL value is to be used. Other values are Prohibited.
    public let ttl: UInt8
    /// The value that is used to calculate when firmware image upload will be suspended.
    ///
    /// The Timeout is calculated using the following formula:
    /// `Timeout = 10 × (Timeout Base + 1)` seconds.
    public let timeoutBase: UInt16
    /// BLOB identifier for the firmware image.
    public let blobId: UInt64
    /// Firmware image size (in octets).
    public let firmwareSize: UInt32
    /// Optional vendor-specific firmware metadata.
    ///
    /// Maximum size is 255 bytes.
    public let firmwareMetadata: Data?
    /// The Firmware ID identifying the firmware image being uploaded.
    public let firmwareId: FirmwareId
    
    public var parameters: Data? {
        var data = Data([ttl]) + timeoutBase + blobId.bigEndian + firmwareSize.bigEndian
        if let metadata = firmwareMetadata {
            data += UInt8(metadata.count)
            data += metadata
        }
        return data + firmwareId.companyIdentifier + firmwareId.version
    }
    
    /// Creates the Firmware Distribution Upload Start message.
    ///
    /// - parameters:
    ///   - blobId: The BLOB identifier for the firmware image to be uploaded.
    ///   - firmwareSize: The size of the firmware image, in octets.
    ///   - firmwareId: The Firmware ID identifying the firmware image being uploaded.
    ///   - metadata: Optional vendor-specific firmware metadata.
    ///   - ttl: The Time To Live (TTL) value used in a firmware image upload.
    ///   - timeoutBase: The value that is used to calculate when firmware image upload will be suspended.
    public init(
        blobWithId blobId: UInt64,
        ofSize firmwareSize: UInt32,
        withFirmwareId firmwareId: FirmwareId,
        andMetadata metadata: Data? = nil,
        usingTtl ttl: UInt8 = 0xFF,
        timeoutBase: UInt16
    ) {
        self.ttl = ttl
        self.timeoutBase = timeoutBase
        self.blobId = blobId
        self.firmwareSize = firmwareSize
        self.firmwareMetadata = metadata
        self.firmwareId = firmwareId
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 18 else {
            return nil
        }
        self.ttl = parameters[0]
        self.timeoutBase = parameters.read(fromOffset: 1)
        self.blobId = parameters.read(fromOffset: 3)
        self.firmwareSize = parameters.read(fromOffset: 11)
        let metadataLength = Int(parameters[15])
        if metadataLength > 0 {
            guard parameters.count >= 18 + metadataLength else {
                return nil
            }
            self.firmwareMetadata = parameters.subdata(in: 16..<16 + metadataLength)
        } else {
            self.firmwareMetadata = nil
        }
        let companyIdentifier: UInt16 = parameters.read(fromOffset: 16 + metadataLength)
        if parameters.count > 18 + metadataLength {
            let version = parameters.subdata(in: 18 + metadataLength..<parameters.count)
            self.firmwareId = FirmwareId(companyIdentifier: companyIdentifier, version: version)
        } else {
            self.firmwareId = FirmwareId(companyIdentifier: companyIdentifier, version: Data())
        }
    }
}
