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

/// The Firmware Update Status message is an unacknowledged message sent by a
/// Firmware Update Server to report the status of a firmware update.
///
/// A Firmware Updates Status message is sent in response to a ``FirmwareUpdateGet`` message,
/// a ``FirmwareUpdateStart`` message, a ``FirmwareUpdateCancel`` message, or
/// a ``FirmwareUpdateApply`` message.
public struct FirmwareUpdateStatus: StaticMeshResponse {
    public static let opCode: UInt32 = 0x8310
    
    /// Status for the requesting message.
    public let status: FirmwareUpdateMessageStatus
    /// The Update Phase state of the Firmware Update Server.
    public let updatePhase: FirmwareUpdatePhase
    /// TTL value to use during firmware image transfer.
    public let updateTtl: UInt8?
    /// The Firmware Update Additional Information state from the Firmware Update Server.
    public let additionalInformation: FirmwareUpdateAdditionalInformation?
    /// The Update Server Timeout Base state is a `UInt16` value that indicates
    /// the timeout after which the Firmware Update Server suspends firmware image
    /// transfer reception.
    ///
    /// The timeout is calculated as `10 * (updateTimeoutBase + 1)` seconds.
    public let updateTimeoutBase: UInt16?
    /// BLOB identifier for the firmware image.
    public let blobId: UInt64?
    /// Index of the firmware image in the Firmware Information List state being updated.
    public let imageIndex: UInt8?
    
    public var parameters: Data? {
        let byte0 = UInt8((status.rawValue & 0x7) | (updatePhase.rawValue << 5))
        if let updateTtl = updateTtl,
           let additionalInformation = additionalInformation,
           let updateTimeoutBase = updateTimeoutBase,
           let blobId = blobId,
           let imageIndex = imageIndex {
            let byte1 = UInt8(updateTtl & 0x7F)
            let byte2 = UInt8(additionalInformation.rawValue & 0x1F)
            return Data([byte0, byte1, byte2]) + updateTimeoutBase + blobId + imageIndex
        } else {
            return Data([byte0])
        }
    }
    
    /// Creates a Firmware Update Status message with given parameters.
    ///
    /// - parameters:
    ///   - status: Status for the requesting message.
    ///   - updatePhase: The Update Phase state of the Firmware Update Server.
    public init(status: FirmwareUpdateMessageStatus,
                updatePhase: FirmwareUpdatePhase) {
        self.status = status
        self.updatePhase = updatePhase
        self.updateTtl = nil
        self.additionalInformation = nil
        self.updateTimeoutBase = nil
        self.blobId = nil
        self.imageIndex = nil
    }
    
    /// Creates a Firmware Update Status message with given parameters.
    ///
    /// - parameters:
    ///   - status: Status for the requesting message.
    ///   - updatePhase: The Update Phase state of the Firmware Update Server.
    ///   - updateTtl: TTL value to use during firmware image transfer.
    ///   - additionalInformation: The Firmware Update Additional Information state from the Firmware Update Server.
    ///   - updateTimeoutBase: The Update Server Timeout Base state.
    ///   - blobId: BLOB identifier for the firmware image.
    ///   - imageIndex: Index of the firmware image in the Firmware Information List state being updated.
    public init(status: FirmwareUpdateMessageStatus,
                updatePhase: FirmwareUpdatePhase,
                updateTtl: UInt8,
                additionalInformation: FirmwareUpdateAdditionalInformation,
                updateTimeoutBase: UInt16,
                blobId: UInt64,
                imageIndex: UInt8) {
        self.status = status
        self.updatePhase = updatePhase
        self.updateTtl = updateTtl
        self.additionalInformation = additionalInformation
        self.updateTimeoutBase = updateTimeoutBase
        self.blobId = blobId
        self.imageIndex = imageIndex
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 1 else {
            return nil
        }
        let byte0 = parameters[0]
        guard let status = FirmwareUpdateMessageStatus(rawValue: byte0 & 0x7) else {
            return nil
        }
        self.status = status
        
        guard let updatePhase = FirmwareUpdatePhase(rawValue: byte0 >> 5) else {
            return nil
        }
        self.updatePhase = updatePhase
        
        if parameters.count > 1 {
            guard parameters.count == 14 else {
                return nil
            }
            self.updateTtl = parameters[1] & 0x7F
            self.additionalInformation = FirmwareUpdateAdditionalInformation(rawValue: parameters[2] & 0x1F)
            self.updateTimeoutBase = parameters.read(fromOffset: 3)
            self.blobId = parameters.read(fromOffset: 5)
            self.imageIndex = parameters[13]
        } else {
            self.updateTtl = nil
            self.additionalInformation = nil
            self.updateTimeoutBase = nil
            self.blobId = nil
            self.imageIndex = nil
        }
    }
}
