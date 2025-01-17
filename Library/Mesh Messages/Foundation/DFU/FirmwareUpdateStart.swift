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

/// The Firmware Update Start message is an acknowledged message used to start
/// a firmware update on a Firmware Update Server.
public struct FirmwareUpdateStart: StaticAcknowledgedMeshMessage {
    public static let opCode: UInt32 = 0x830D
    public static let responseType: StaticMeshResponse.Type = FirmwareUpdateStatus.self
    
    /// The Time To Live (TTL) value to use during firmware image transfer.
    ///
    /// Valid value is in range 0...127 or 255 (0xFF) to use the default TTL value.
    /// Values 128-254 are prohibited.
    public let updateTtl: UInt8
    /// The Update Server Timeout Base state is a `UInt16` value that indicates
    /// the timeout after which the Firmware Update Server suspends firmware image
    /// transfer reception.
    ///
    /// The timeout is calculated as `10 * (updateTimeoutBase + 1)` seconds.
    public let updateTimeoutBase: UInt16
    /// BLOB identifier for the firmware image.
    ///
    /// The BLOB ID state is an `UInt64` value that uniquely identifies a BLOB on a network.
    public let blobId: UInt64
    /// Index of the firmware image in the Firmware Information List state to be updated.
    public let imageIndex: UInt8
    /// Vendor-specific firmware metadata.
    ///
    /// If present, the Incoming Firmware Metadata field contains the custom data from
    /// the firmware vendor that is used to check whether the firmware image can be updated.
    ///
    /// Maximum size is 255 bytes. Metadata should be omitted it empty.
    public let metadata: Data?
    
    public var parameters: Data? {
        return Data([updateTtl]) + updateTimeoutBase + blobId + imageIndex + metadata
    }
    
    /// Creates the Firmware Update Start message.
    ///
    /// - parameters:
    ///  - updateTtl: The Time To Live (TTL) value to use during firmware image transfer.
    ///  - updateTimeoutBase: The Update Server Timeout Base state.
    ///  - blobId: BLOB identifier for the firmware image.
    ///  - imageIndex: Index of the firmware image in the Firmware Information List state to be updated.
    ///  - metadata: Optional vendor-specific firmware metadata.
    public init(updateTtl: UInt8, updateTimeoutBase: UInt16, blobId: UInt64, imageIndex: UInt8, metadata: Data?) {
        self.updateTtl = updateTtl
        self.updateTimeoutBase = updateTimeoutBase
        self.blobId = blobId
        self.imageIndex = imageIndex
        self.metadata = metadata
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 12 else {
            return nil
        }
        updateTtl = parameters[0]
        updateTimeoutBase = parameters.read(fromOffset: 1)
        blobId = parameters.read(fromOffset: 3)
        imageIndex = parameters[11]
        
        if (parameters.count > 12) {
            metadata = parameters.subdata(in: 12..<parameters.count)
        } else {
            metadata = nil
        }
    }
}
