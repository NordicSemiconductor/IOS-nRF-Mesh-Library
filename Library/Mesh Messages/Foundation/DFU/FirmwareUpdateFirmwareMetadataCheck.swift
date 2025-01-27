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

/// The Firmware Update Firmware Metadata Check message is an acknowledged message,
/// sent to a Firmware Update Server, to check whether the Node can accept a firmware update.
public struct FirmwareUpdateFirmwareMetadataCheck: StaticAcknowledgedMeshMessage {
    public static let opCode: UInt32 = 0x830A
    public static let responseType: StaticMeshResponse.Type = FirmwareUpdateFirmwareMetadataStatus.self
    
    /// Index of the firmware image in the Firmware Information List state to check.
    ///
    /// The Update Firmware Image Index field shall identify the firmware image in the
    /// Firmware Information List state on the Firmware Update Server that the metadata is checked
    /// against.
    public let imageIndex: UInt8
    /// Vendor-specific metadata.
    ///
    /// If present, the Incoming Firmware Metadata field shall contain the custom data from the
    /// firmware vendor. The firmware metadata can be used to check whether the installed firmware
    /// image identified by the Firmware Image Index field will accept an update based on the metadata
    /// provided for the new firmware image.
    ///
    /// Maximum size is 255 bytes. Metadata should be omitted it empty.
    public let metadata: Data?
    
    public var parameters: Data? {
        return Data([imageIndex]) + metadata
    }
    
    
    /// Creates the Firmware Update Firmware Metadata Check message.
    ///
    /// - parameters:
    ///   - imageIndex: Index of the firmware image in the Firmware Information List state to check.
    ///   - metadata: Optional vendor-specific metadata of the incoming Firmware.
    public init(imageIndex: UInt8, metadata: Data?) {
        self.imageIndex = imageIndex
        self.metadata = metadata
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 1 else {
            return nil
        }
        imageIndex = parameters[0]
        
        if (parameters.count > 1) {
            metadata = parameters.subdata(in: 1..<parameters.count)
        } else {
            metadata = nil
        }
    }
}
