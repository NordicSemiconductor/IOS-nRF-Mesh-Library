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

/// The Firmware Update Firmware Metadata Status message is an unacknowledged message
/// sent to a Firmware Update Client that is used to report whether a Firmware Update Server can
/// accept a firmware update.
///
/// The Firmware Update Firmware Metadata Status message is sent in response to
/// a ``FirmwareUpdateFirmwareMetadataCheck`` message.
public struct FirmwareUpdateFirmwareMetadataStatus: StaticMeshResponse {
    public static let opCode: UInt32 = 0x830B
    
    /// Status from the firmware metadata check.
    public let status: FirmwareUpdateMessageStatus
    /// The Firmware Update Additional Information state from the Firmware Update Server.
    public let additionalInformation: FirmwareUpdateAdditionalInformation
    /// Index of the firmware image in the Firmware Information List state that was checked.
    public let imageIndex: UInt8
    
    public var parameters: Data? {
        let byte0 = UInt8((status.rawValue & 0x7) | (additionalInformation.rawValue << 3))
        return Data([byte0, imageIndex])
    }
    
    /// Creates the Firmware Update Firmware Metadata Status message.
    ///
    /// - parameters:
    ///   - status: Status from the firmware metadata check. This should be one of:
    ///             ``FirmwareUpdateMessageStatus/success``,
    ///             ``FirmwareUpdateMessageStatus/metadataCheckFailed``,
    ///             or ``FirmwareUpdateMessageStatus/wrongFirmwareIndex``.
    ///   - additionalInformation:The Firmware Update Additional Information state from the
    ///                           Firmware Update Server.
    ///   - imageIndex: Index of the firmware image in the Firmware Information List state that was checked.
    public init(status: FirmwareUpdateMessageStatus, additionalInformation: FirmwareUpdateAdditionalInformation, imageIndex: UInt8) {
        self.status = status
        self.additionalInformation = additionalInformation
        self.imageIndex = imageIndex
    }
    
    /// Creates the Firmware Update Firmware Metadata Status message.
    ///
    /// - parameters:
    ///   - request: The Firmware Update Firmware Metadata Check message to response to.
    ///   - status: Status from the firmware metadata check. This should be one of:
    ///             ``FirmwareUpdateMessageStatus/success``,
    ///             ``FirmwareUpdateMessageStatus/metadataCheckFailed``,
    ///             or ``FirmwareUpdateMessageStatus/wrongFirmwareIndex``.
    ///   - additionalInformation:The Firmware Update Additional Information state from the
    ///                           Firmware Update Server.   
    public init(responseTo request: FirmwareUpdateFirmwareMetadataCheck,
                with status: FirmwareUpdateMessageStatus,
                additionalInformation: FirmwareUpdateAdditionalInformation) {
        self.status = status
        self.additionalInformation = additionalInformation
        self.imageIndex = request.imageIndex
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 2 else {
            return nil
        }
        let byte0 = parameters[0]
        
        guard let status = FirmwareUpdateMessageStatus(rawValue: byte0 & 0x7) else {
            return nil
        }
        self.status = status
        guard let additionalInformation = FirmwareUpdateAdditionalInformation(rawValue: byte0 >> 3) else {
            return nil
        }
        self.additionalInformation = additionalInformation
        self.imageIndex = parameters[1]
    }
}
