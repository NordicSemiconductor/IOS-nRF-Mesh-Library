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

/// The Firmware Distribution Upload Status message is an unacknowledged message sent by
/// a Firmware Distribution Server to report the status of a firmware image upload.
///
/// A Firmware Distribution Upload Status message is sent as a response to any of:
/// * ``FirmwareDistributionUploadGet``,
/// * ``FirmwareDistributionUploadStart``,
/// * ``FirmwareDistributionUploadOOBStart``,
/// * ``FirmwareDistributionCancel``,
public struct FirmwareDistributionUploadStatus: StaticMeshResponse {
    public static let opCode: UInt32 = 0x8322
    
    /// Status for the requesting message.
    public let status: FirmwareDistributionMessageStatus
    /// Phase of the firmware image upload to a Firmware Distribution Server.
    public let phase: FirmwareDistributionPhase
    /// A percentage indicating the progress of the firmware image upload (0-100).
    public let progress: UInt8?
    /// Whether the upload is done Out of Band (true) or using BLOB Transfer (false).
    public let isOob: Bool?
    /// The Firmware ID of the new firmware image that is being uploaded or was
    /// uploaded to the Firmware Distribution Server.
    public  let firmwareId: FirmwareId?
    
    public var parameters: Data? {
        var data = Data([status.rawValue, phase.rawValue])
        
        // Optional fields shall be present when the distribution address is present.
        if let progress = progress,
           let isOob = isOob,
           let firmwareId = firmwareId {
            // 7 bits for the progress and 1 for Upload Type field.
            data += UInt8((progress << 1) | (isOob ? 1 : 0))
            data += firmwareId.companyIdentifier
            data += firmwareId.version
        }
        return data
    }
    
    /// Creates the Firmware Distribution Upload Status message for the Idle state.
    ///
    /// - parameter status: Status for the requesting message.
    public init(report status: FirmwareDistributionMessageStatus) {
        self.status = status
        // The following fields shall only be omitted in .idle state.
        self.phase = .idle
        self.progress = nil
        self.isOob = nil
        self.firmwareId = nil
    }
    
    /// Creates the Firmware Distribution Upload Status message.
    ///
    /// This constructor SHALL NOT be used for ``FirmwareDistributionPhase/idle`` phase,
    /// as then all the parameters shall be omitted. Use ``init(report:)`` instead.
    ///
    /// - parameters:
    ///   - status: Status for the requesting message.
    ///   - phase: The phase of the firmware image upload.
    ///   - firmwareId: The Firmware ID of the new firmware image that is being uploaded.
    ///   - isOob: Whether the upload is done Out of Band (true) or using BLOB Transfer (false).
    ///   - progress: A percentage indicating the progress of the firmware image upload (0-100).
    public init(
        report status: FirmwareDistributionMessageStatus,
        andPhase phase: FirmwareDistributionPhase,
        ofUploadingFirmwareWithId firmwareId: FirmwareId,
        oufOfBand isOob: Bool,
        progress: UInt8
    ) {
        self.status = status
        self.phase = phase
        self.progress = progress
        self.isOob = isOob
        self.firmwareId = firmwareId
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 2 || parameters.count >= 5 else {
            return nil
        }
        guard let status = FirmwareDistributionMessageStatus(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        guard let phase = FirmwareDistributionPhase(rawValue: parameters[1]) else {
            return nil
        }
        self.phase = phase
        
        if parameters.count >= 5 {
            self.progress = parameters[2] >> 1
            self.isOob = parameters[2] & 0x01 == 1
            
            let companyIdentifier: UInt16 = parameters.read(fromOffset: 3)
            if parameters.count > 5 {
                let version = parameters.subdata(in: 5..<parameters.count)
                self.firmwareId = FirmwareId(companyIdentifier: companyIdentifier, version: version)
            } else {
                self.firmwareId = FirmwareId(companyIdentifier: companyIdentifier, version: Data())
            }
        } else {
            self.progress = nil
            self.isOob = nil
            self.firmwareId = nil
        }
    }
}
