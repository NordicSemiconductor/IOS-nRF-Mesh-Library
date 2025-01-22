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

/// The Firmware Distribution Capabilities Status message is an unacknowledged message
/// sent by a Firmware Distribution Server to report Distributor capabilities.
///
/// A Firmware Distribution Capabilities Status message is sent as a response to
/// a ``FirmwareDistributorCapabilitiesGet`` message.
public struct FirmwareDistributionCapabilitiesStatus: StaticMeshResponse {
    public static let opCode: UInt32 = 0x8317
    
    /// Maximum number of entries in the Distribution Receivers List state.
    let maxReceiversCount: UInt16
    /// Maximum number of entries in the Firmware Images List state.
    let maxFirmwareImagesListSize: UInt16
    /// Maximum size of one firmware image (in octets).
    let maxFirmwareImageSize: UInt32
    /// Total space dedicated to storage of firmware images (in octets).
    let maxUploadSpace: UInt32
    /// Remaining available space in firmware image storage (in octets).
    let remainingUploadSpace: UInt32
    /// Supported Out-of-Band URI schemes.
    ///
    /// If the array is empty, the OOB Retrieval is not supported.
    let supportedUriSchemes: [UriScheme]
    
    public var parameters: Data? {
        let data = Data() + maxReceiversCount + maxFirmwareImagesListSize + maxFirmwareImageSize + maxUploadSpace + remainingUploadSpace
        if supportedUriSchemes.isEmpty {
            return data + UInt8(0x00)
        } else {
            return supportedUriSchemes.reduce(data + UInt8(0x01)) { $0 + $1.rawValue }
        }
    }
    
    /// Creates the Firmware Distribution Capabilities Status message.
    ///
    /// - parameters:
    ///   - maxReceiversCount: Maximum number of entries in the Distribution Receivers List state.
    ///   - maxFirmwareImagesListSize: Maximum number of entries in the Firmware Images List state.
    ///   - maxFirmwareImageSize: Maximum size of one firmware image (in octets).
    ///   - maxUploadSpace: Total space dedicated to storage of firmware images (in octets).
    ///   - remainingUploadSpace: Remaining available space in firmware image storage (in octets).
    ///   - supportedUriSchemes: Supported Out-of-Band URI schemes. If the array is empty, the OOB Retrieval is not supported.
    public init(
        maxReceiversCount: UInt16,
        maxFirmwareImagesListSize: UInt16,
        maxFirmwareImageSize: UInt32,
        maxUploadSpace: UInt32,
        remainingUploadSpace: UInt32,
        supportedUriSchemes: [UriScheme] = []
    ) {
        self.maxReceiversCount = maxReceiversCount
        self.maxFirmwareImagesListSize = maxFirmwareImagesListSize
        self.maxFirmwareImageSize = maxFirmwareImageSize
        self.maxUploadSpace = maxUploadSpace
        self.remainingUploadSpace = remainingUploadSpace
        self.supportedUriSchemes = supportedUriSchemes
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 17 else {
            return nil
        }
        maxReceiversCount = parameters.read(fromOffset: 0)
        maxFirmwareImagesListSize = parameters.read(fromOffset: 2)
        maxFirmwareImageSize = parameters.read(fromOffset: 4)
        maxUploadSpace = parameters.read(fromOffset: 8)
        remainingUploadSpace = parameters.read(fromOffset: 12)
        
        let oobRetrievalSupported = parameters[16] == 0x01
        if oobRetrievalSupported {
            guard parameters.count >= 18 else {
                return nil
            }
            supportedUriSchemes = parameters[17...].compactMap { UriScheme(rawValue: $0) }
        } else {
            supportedUriSchemes = []
        }
    }
}
